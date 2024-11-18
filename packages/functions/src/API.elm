module API exposing (main)

import Momento exposing (Error, Op, OpenParams, SubscribeParams)
import Ports
import Server.API as Api


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

    -- Elm modules
    , api : Api.Model
    , momento : Momento.Model

    -- Routing state
    -- Shared state
    }


type Msg
    = MomentoMsg Momento.Msg
    | ApiMsg Api.Msg


type alias MomentoSecret =
    { apiKey : String
    , refreshToken : String
    , restEndpoint : String
    }


type alias Flags =
    { momentoSecret : MomentoSecret
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
        ( appMdl, appCmds ) =
            Api.init apiProtocol.toMsg

        ( socketsMdl, socketsCmds ) =
            Momento.init MomentoMsg momentoPorts
    in
    ( { momentoApiKey = flags.momentoSecret.apiKey
      , api = appMdl
      , momento = socketsMdl
      }
    , Cmd.batch
        [ appCmds
        , socketsCmds
        ]
    )


momentoPorts : Momento.Ports
momentoPorts =
    { open = Ports.mmOpen
    , onOpen = Ports.mmOnOpen
    , close = Ports.mmClose
    , subscribe = Ports.mmSubscribe
    , onSunscribe = Ports.mmOnSubscribe
    , publish = Ports.mmSend
    , onMessage = Ports.mmOnMessage
    , pushList = Ports.mmPushList
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


apiPorts : Api.Ports
apiPorts =
    { request = Ports.requestPort
    , response = Ports.responsePort
    }


apiProtocol : Api.Protocol Model Msg Model
apiProtocol =
    { toMsg = ApiMsg
    , ports = apiPorts
    , onUpdate = identity

    --, mmOpen = \id params -> U2.andThen (mmOpen id params)
    --, mmSubscribe = \id params -> U2.andThen (mmSubscribe id params)
    --, mmOps = \id ops -> U2.andThen (mmOps id ops)
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Api.subscriptions apiProtocol model.api
        , Momento.subscriptions (momentoProtocol model) model.momento
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MomentoMsg innerMsg ->
            Momento.update (momentoProtocol model)
                innerMsg
                model.momento

        ApiMsg innerMsg ->
            Api.update apiProtocol
                innerMsg
                model


mmOpened : String -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmOpened id model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )


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


mmOpen : String -> OpenParams -> Model -> ( Model, Cmd Msg )
mmOpen id params model =
    Momento.open (momentoProtocol model) id params model.momento


mmSubscribe : String -> SubscribeParams -> Model -> ( Model, Cmd Msg )
mmSubscribe id params model =
    Momento.subscribe (momentoProtocol model) id params model.momento


mmOps : String -> List Op -> Model -> ( Model, Cmd Msg )
mmOps id ops model =
    Momento.processOps (momentoProtocol model) id ops model.momento
