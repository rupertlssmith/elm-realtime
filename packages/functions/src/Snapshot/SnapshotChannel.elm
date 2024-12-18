module Snapshot.SnapshotChannel exposing (..)

import AWS.Credentials exposing (Credentials)
import AWS.Dynamo as Dynamo exposing (Error(..), Order(..))
import Dict exposing (Dict)
import ErrorFormat exposing (ErrorFormat)
import Http.Response as Response exposing (Response)
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Procedure
import Realtime exposing (Snapshot, SnapshotEvent)
import Snapshot.Model exposing (Model(..), ReadyState)
import Snapshot.Msg exposing (Msg(..))
import SqsLambda exposing (SqsEvent)
import Update2 as U2


type alias SnapshotChannel a =
    { a
        | awsRegion : String
        , defaultCredentials : Credentials
        , momentoApiKey : String
        , eventLogTable : String
        , snapshotTable : String
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


procedure :
    HttpSessionKey
    -> ReadyState
    -> SqsEvent
    -> SnapshotChannel a
    -> ( SnapshotChannel a, Cmd Msg )
procedure session state sqsEvent component =
    let
        updateHighest new maybeExisting =
            case maybeExisting of
                Just existing ->
                    if new.seq > existing.seq then
                        Just new

                    else
                        Just existing

                Nothing ->
                    Just new

        snapshotSeqByChannel =
            List.foldl
                (\sqsMessage acc ->
                    Decode.decodeString Realtime.snapshotEventDecoder sqsMessage.body
                        |> Result.map
                            (\snapshotEvent ->
                                Dict.update
                                    snapshotEvent.channel
                                    (updateHighest snapshotEvent)
                                    acc
                            )
                        |> Result.withDefault acc
                )
                Dict.empty
                sqsEvent
                |> Dict.values
                |> Debug.log "snapshotSeqByChannel"

        innerProc : Procedure.Procedure Response Response Msg
        innerProc =
            Procedure.provide snapshotSeqByChannel
                |> Procedure.andThen (drainSnapshotRequests component state)
                |> Procedure.mapError (Debug.log "error" >> ErrorFormat.encodeErrorFormat >> Response.err500json)
                |> Procedure.map (Response.ok200json Encode.null |> always)
    in
    ( state
    , Procedure.try ProcedureMsg (HttpResponse session) innerProc
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)


drainSnapshotRequests :
    SnapshotChannel a
    -> { cache : Dict String (Snapshot Value) }
    -> List SnapshotEvent
    -> Procedure.Procedure ErrorFormat { cache : Dict String (Snapshot Value) } Msg
drainSnapshotRequests component state snapshotSeqByChannel =
    case snapshotSeqByChannel of
        [] ->
            Procedure.provide state

        snapshotEvent :: events ->
            snapshotChannel component state snapshotEvent
                |> Procedure.andThen (\_ -> drainSnapshotRequests component state events)


{-| Snapshot Channel:

    * Check any cached snapshot, if the request is for a higher snapshot then continue.
    * Fetch the latest snapshot stored if newer than the cached one, if the request is
      still for a higher snapshot then continue.
    * Read events from the event log from the latest snapshot onwards.
    * Play the event log forward on top of the snapshot.
    * Write the new snapshot into the snapshot table with the correct sequence number.
    * Retain the new snapshot in the cache.

-}
snapshotChannel :
    SnapshotChannel a
    -> { cache : Dict String (Snapshot Value) }
    -> SnapshotEvent
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , maybeLatest : Maybe (Snapshot Value)
            }
            Msg
snapshotChannel component state event =
    Procedure.provide state
        |> Procedure.andThen (getLatestSnapshotFromCache component event)
        |> Procedure.andThen
            (\{ cache, maybeLatest } ->
                case maybeLatest of
                    Just latest ->
                        if latest.seq >= event.seq then
                            Procedure.provide { cache = cache, maybeLatest = Just latest }

                        else
                            Procedure.provide { cache = cache, maybeLatest = Nothing }

                    Nothing ->
                        getLatestSnapshotFromTable component event { cache = state.cache }
            )


getLatestSnapshotFromCache :
    SnapshotChannel a
    -> SnapshotEvent
    -> { cache : Dict String (Snapshot Value) }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , maybeLatest : Maybe (Snapshot Value)
            }
            Msg
getLatestSnapshotFromCache component event state =
    Procedure.provide
        { cache = state.cache
        , maybeLatest = Dict.get event.channel state.cache
        }


getLatestSnapshotFromTable :
    SnapshotChannel a
    -> SnapshotEvent
    -> { cache : Dict String (Snapshot Value) }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , maybeLatest : Maybe (Snapshot Value)
            }
            Msg
getLatestSnapshotFromTable component event state =
    let
        matchLatestSnapshot =
            Dynamo.partitionKeyEquals "id" event.channel
                |> Dynamo.orderResults Reverse
                |> Dynamo.limitResults 1

        query =
            { tableName = component.snapshotTable
            , match = matchLatestSnapshot
            }
    in
    --Apis.snapshotTableApi.query query
    --    |> Procedure.fetchResult
    --    |> Procedure.mapError Dynamo.errorToDetails
    --    |> Procedure.map
    --        (\queryResult ->
    --            case queryResult of
    --                [] ->
    --                    { cache = state.cache, maybeLatest = Nothing }
    --
    --                r :: _ ->
    --                    { cache = state.cache, maybeLatest = Just r }
    --        )
    Debug.todo ""
