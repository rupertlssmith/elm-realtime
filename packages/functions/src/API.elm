module API exposing (Flags, Model, MomentoSecret, Msg, main)

import EventLog.Component as EventLog
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
    , eventLog : EventLog.Model

    -- Routing state
    -- Shared state
    }


type Msg
    = ApiMsg Api.Msg
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

        ( eventLogMdl, eventLogCmds ) =
            EventLog.init EventLogMsg
    in
    ( { momentoApiKey = flags.momentoSecret.apiKey
      , channelApiUrl = flags.channelApiUrl
      , api = apiMdl
      , eventLog = eventLogMdl
      }
    , Cmd.batch
        [ apiCmds
        , eventLogCmds
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Api.subscriptions (apiProtocol model) model.api
        , EventLog.subscriptions eventLogProtocol model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "API.update" msg of
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



-- EventLog Protocol


eventLogProtocol : EventLog.Protocol Model Msg Model
eventLogProtocol =
    { toMsg = EventLogMsg
    , onUpdate = identity
    }
