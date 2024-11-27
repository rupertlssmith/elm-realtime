module API exposing (Flags, Model, MomentoSecret, Msg, main)

import EventLog.Component as EventLog


{-| API for managing realtime channels.
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
    case msg of
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
