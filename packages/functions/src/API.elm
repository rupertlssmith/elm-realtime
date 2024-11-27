module API exposing (Flags, Model, MomentoSecret, Msg, main)

import EventLog.Component as EventLog


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
    , eventLog : EventLog.Model

    -- Shared state
    }


type Msg
    = EventLogMsg EventLog.Msg


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
        ( eventLogMdl, eventLogCmds ) =
            EventLog.init EventLogMsg
    in
    ( { momentoApiKey = flags.momentoSecret.apiKey
      , channelApiUrl = flags.channelApiUrl
      , eventLog = eventLogMdl
      }
    , Cmd.batch
        [ eventLogCmds
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ EventLog.subscriptions eventLogProtocol model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "API.update" msg of
        EventLogMsg innerMsg ->
            EventLog.update eventLogProtocol
                innerMsg
                model



-- EventLog Protocol


eventLogProtocol : EventLog.Protocol Model Msg Model
eventLogProtocol =
    { toMsg = EventLogMsg
    , onUpdate = identity
    }
