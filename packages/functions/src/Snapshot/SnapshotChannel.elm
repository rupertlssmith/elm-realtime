module Snapshot.SnapshotChannel exposing (..)

import AWS.Config exposing (Region)
import AWS.Credentials exposing (Credentials)
import AWS.Dynamo as Dynamo exposing (Error(..))
import AWS.Http exposing (Error(..))
import AWS.Sqs as Sqs
import DB.EventLogTable as EventLogTable
import Dict
import ErrorFormat exposing (ErrorFormat)
import Http.Response as Response exposing (Response)
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Extra as DE
import Json.Encode as Encode
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Names
import Procedure
import Snapshot.Apis as Apis
import Snapshot.Model exposing (Model(..), ReadyState)
import Snapshot.Msg exposing (Msg(..))
import SqsLambda exposing (SqsEvent)
import Time exposing (Posix)
import Update2 as U2


type alias SnapshotChannel a =
    { a
        | awsRegion : String
        , defaultCredentials : Credentials
        , momentoApiKey : String
        , eventLogTable : String
        , snapshotQueueUrl : String
        , snapshot : Model
    }


setModel : SnapshotChannel a -> Model -> SnapshotChannel a
setModel m x =
    { m | snapshot = x }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


{-| Snapshot Channel:

    * Fetch the latest snapshot stored, if the request is for a higher snapshot then continue.
    * Read events from the event log from the latest snapshot onwards.
    * Play the event log forward on top of the snapshot.
    * Write the new snapshot into the snapshot table with the correct sequence number.

-}
snapshotChannel :
    HttpSessionKey
    -> ReadyState
    -> SqsEvent
    -> String
    -> SnapshotChannel a
    -> ( SnapshotChannel a, Cmd Msg )
snapshotChannel session state apiRequest channelName component =
    let
        procedure : Procedure.Procedure Response Response Msg
        procedure =
            Procedure.provide channelName
                |> Procedure.andThen (Debug.todo "")
                |> Procedure.mapError (Debug.log "error" >> ErrorFormat.encodeErrorFormat >> Response.err500json)
                |> Procedure.map (Response.ok200json Encode.null |> always)
    in
    ( state
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)
