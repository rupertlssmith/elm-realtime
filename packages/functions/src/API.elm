module API exposing (Flags, Model, MomentoSecret, Msg, main)

import EventLog.Component as EventLog
import Momento exposing (Error, Op, OpenParams, SubscribeParams)
import Ports
import Server.API as Api exposing (ApiRoute)
import Update2 as U2


{-| API for managing realtime channels.

Channel creation:

    * Create the cache or confirm it already exists.
    * Create a webhook on the save topic.
    * Create a dynamodb table for the persisted events.
    * Return a confirmation that everything has been set up.

Channel save:

    * Obtain a connection to the cache.
    * Read the saved events from the cache list.
    * Save the events to the dynamodb event log.
    * Remove the saved events from the cache list.
    * Publish the saved event to the model topic.

-}
type alias Model =
    { -- Flags
      momentoApiKey : String
    , channelApiUrl : String

    -- Elm modules
    , api : Api.Model
    , momento : Momento.Model
    , eventLog : EventLog.Model

    -- Routing state
    -- Shared state
    }


type Msg
    = MomentoMsg Momento.Msg
    | ApiMsg Api.Msg
    | EventLogMsg EventLog.Msg


type alias MomentoSecret =
    { apiKey : String
    , refreshToken : String
    , restEndpoint : String
    }


type alias Flags =
    { momentoSecret : MomentoSecret
    , channelApiUrl : String
    }


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( apiMdl, apiCmds ) =
            Api.init ApiMsg

        ( momentoMdl, momentoCmds ) =
            Momento.init MomentoMsg momentoPorts

        ( eventLogMdl, eventLogCmds ) =
            EventLog.init EventLogMsg
    in
    ( { momentoApiKey = flags.momentoSecret.apiKey
      , channelApiUrl = flags.channelApiUrl
      , api = apiMdl
      , momento = momentoMdl
      , eventLog = eventLogMdl
      }
    , Cmd.batch
        [ apiCmds
        , momentoCmds
        , eventLogCmds
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Api.subscriptions (apiProtocol model) model.api
        , Momento.subscriptions (momentoProtocol model) model.momento
        , EventLog.subscriptions eventLogProtocol model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "API.update" msg of
        MomentoMsg innerMsg ->
            Momento.update (momentoProtocol model)
                innerMsg
                model.momento

        ApiMsg innerMsg ->
            Api.update (apiProtocol model)
                innerMsg
                model.api

        EventLogMsg innerMsg ->
            EventLog.update eventLogProtocol
                innerMsg
                model



-- API Protocol


apiPorts : Api.Ports
apiPorts =
    { request = Ports.requestPort
    , response = Ports.responsePort
    }


apiProtocol : Model -> Api.Protocol Api.Model Msg Model EventLog.Route
apiProtocol model =
    { toMsg = ApiMsg
    , ports = apiPorts
    , parseRoute = EventLog.routeParser
    , onUpdate = \( apiMdl, cmds ) -> ( { model | api = apiMdl }, cmds )
    , onApiRoute = \route -> apiRoute route model
    }


apiRoute : ApiRoute EventLog.Route -> Model -> ( Api.Model, Cmd Msg ) -> ( Model, Cmd Msg )
apiRoute route model =
    \( apiMdl, cmds ) ->
        ( { model | api = apiMdl }, cmds )
            |> U2.andThen (EventLog.processRoute eventLogProtocol route)



-- Momento Protocol


momentoPorts : Momento.Ports
momentoPorts =
    { open = Ports.mmOpen
    , onOpen = Ports.mmOnOpen
    , close = Ports.mmClose
    , subscribe = Ports.mmSubscribe
    , onSubscribe = Ports.mmOnSubscribe
    , publish = Ports.mmSend
    , onMessage = Ports.mmOnMessage
    , pushList = Ports.mmPushList
    , createWebhook = Ports.mmCreateWebhook
    , onError = Ports.mmOnError
    }


momentoProtocol : Model -> Momento.Protocol Momento.Model Msg Model
momentoProtocol model =
    { toMsg = MomentoMsg
    , ports = momentoPorts
    , onUpdate = \( wsMdl, cmds ) -> ( { model | momento = wsMdl }, cmds )
    , onOpen = \id -> mmOpened id model
    , onSubscribe = \id params -> mmSubscribed id params model
    , onMessage = \id payload -> mmMessage id payload model
    , onError = \id error -> mmError id error model
    }


mmOpened : String -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmOpened id model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )
            |> U2.andThen (EventLog.mmOpened eventLogProtocol id)


mmSubscribed : String -> SubscribeParams -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmSubscribed id params model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )


mmMessage : String -> String -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmMessage id payload model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )


mmError : String -> Error -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmError id payload model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )
            |> U2.andThen (EventLog.mmError eventLogProtocol id payload)



-- EventLog Protocol


eventLogProtocol : EventLog.Protocol Model Msg Model
eventLogProtocol =
    { toMsg = EventLogMsg
    , onUpdate = identity
    , mmOpen = \id params -> U2.andThen (mmOpen id params)
    , mmOps = \id ops -> U2.andThen (mmOps id ops)
    }


mmOpen : String -> OpenParams -> Model -> ( Model, Cmd Msg )
mmOpen id params model =
    Momento.open (momentoProtocol model) id params model.momento


mmSubscribe : String -> SubscribeParams -> Model -> ( Model, Cmd Msg )
mmSubscribe id params model =
    Momento.subscribe (momentoProtocol model) id params model.momento


mmOps : String -> List Op -> Model -> ( Model, Cmd Msg )
mmOps id ops model =
    Momento.processOps (momentoProtocol model) id ops model.momento
