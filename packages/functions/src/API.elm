module API exposing (Flags, Model, MomentoSecret, Msg, main)

import AWS.Credentials exposing (Credentials)
import EventLog.Component as EventLog
import Snapshot.Component as Snapshot


{-| API for managing realtime channels.
-}
type alias Model =
    { -- Flags
      awsRegion : String
    , awsAccessKeyId : String
    , awsSecretAccessKey : String
    , awsSessionToken : String
    , momentoApiKey : String
    , channelApiUrl : String
    , channelTable : String
    , eventLogTable : String
    , snapshotQueueUrl : String
    , defaultCredentials : Credentials

    -- Elm modules
    , eventLog : EventLog.Model
    , snapshot : Snapshot.Model

    -- Shared state
    }


type Msg
    = EventLogMsg EventLog.Msg
    | SnapshotMsg Snapshot.Msg


type alias MomentoSecret =
    { apiKey : String
    , refreshToken : String
    , restEndpoint : String
    }


type alias Flags =
    { awsRegion : String
    , awsAccessKeyId : String
    , awsSecretAccessKey : String
    , awsSessionToken : String
    , momentoSecret : MomentoSecret
    , channelApiUrl : String
    , channelTable : String
    , eventLogTable : String
    , snapshotQueueUrl : String
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

        ( snapshotMdl, snapshotCmds ) =
            Snapshot.init SnapshotMsg

        credentials =
            AWS.Credentials.fromAccessKeys
                flags.awsAccessKeyId
                flags.awsSecretAccessKey
                |> AWS.Credentials.withSessionToken flags.awsSessionToken
    in
    ( { awsRegion = flags.awsRegion
      , awsAccessKeyId = flags.awsAccessKeyId
      , awsSecretAccessKey = flags.awsSecretAccessKey
      , awsSessionToken = flags.awsSessionToken
      , momentoApiKey = flags.momentoSecret.apiKey
      , channelApiUrl = flags.channelApiUrl
      , channelTable = flags.channelTable
      , eventLogTable = flags.eventLogTable
      , snapshotQueueUrl = flags.snapshotQueueUrl
      , defaultCredentials = credentials
      , eventLog = eventLogMdl
      , snapshot = snapshotMdl
      }
    , Cmd.batch
        [ eventLogCmds
        , snapshotCmds
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ EventLog.subscriptions eventLogProtocol model
        , Snapshot.subscriptions snapshotProtocol model
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EventLogMsg innerMsg ->
            EventLog.update eventLogProtocol
                innerMsg
                model

        SnapshotMsg innerMsg ->
            Snapshot.update snapshotProtocol
                innerMsg
                model



-- EventLog Protocol


eventLogProtocol : EventLog.Protocol Model Msg Model
eventLogProtocol =
    { toMsg = EventLogMsg
    , onUpdate = identity
    }


snapshotProtocol : Snapshot.Protocol Model Msg Model
snapshotProtocol =
    { toMsg = SnapshotMsg
    , onUpdate = identity
    }
