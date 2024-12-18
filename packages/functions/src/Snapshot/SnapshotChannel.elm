module Snapshot.SnapshotChannel exposing (..)

import AWS.Credentials exposing (Credentials)
import AWS.Dynamo as Dynamo exposing (Error(..), Order(..))
import DB.EventLogTable as EventLog
import Dict exposing (Dict)
import ErrorFormat exposing (ErrorFormat)
import Http.Response as Response exposing (Response)
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Procedure
import Realtime exposing (Snapshot, SnapshotEvent)
import Snapshot.Apis as Apis
import Snapshot.Model exposing (Model(..), ReadyState)
import Snapshot.Msg exposing (Msg(..))
import SqsLambda exposing (SqsEvent)
import Time
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
            Procedure.provide { cache = state.cache }
                |> Procedure.andThen (drainSnapshotRequests component snapshotSeqByChannel)
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
    -> List SnapshotEvent
    -> { cache : Dict String (Snapshot Value) }
    -> Procedure.Procedure ErrorFormat { cache : Dict String (Snapshot Value) } Msg
drainSnapshotRequests component snapshotSeqByChannel state =
    case snapshotSeqByChannel of
        [] ->
            Procedure.provide state

        snapshotEvent :: events ->
            Procedure.provide state
                |> Procedure.andThen (snapshotChannel component snapshotEvent)
                |> Procedure.andThen (drainSnapshotRequests component events)


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
    -> SnapshotEvent
    -> { cache : Dict String (Snapshot Value) }
    -> Procedure.Procedure ErrorFormat { cache : Dict String (Snapshot Value) } Msg
snapshotChannel component event state =
    Procedure.provide state
        |> Procedure.andThen (checkAgainstCurrentSnapshot component event)
        |> Procedure.andThen
            (\condition ->
                case condition of
                    LaterFound cache ->
                        Procedure.provide { cache = cache }

                    OutOfDate snapshot ->
                        Procedure.provide { cache = state.cache, baseSnapshot = Just snapshot }
                            |> Procedure.andThen (readLaterEvents component event)
                            |> Procedure.andThen (saveNextSnapshot component event)

                    New ->
                        Procedure.provide { cache = state.cache, baseSnapshot = Nothing }
                            |> Procedure.andThen (readLaterEvents component event)
                            |> Procedure.andThen (saveNextSnapshot component event)
            )


{-| Check the snapshot event against the current snapshot, in the cache and in the snapshot table. The possible
outcomes of this are:

    1. A snapshot with the same or newer sequence number already exists. An updated snapshot cache will be
    created for this, which should be retained.
    2. A snapshot with lower sequence number exists. This is to be used as the starting point for building the
    next snapshot.
    3. No prior snapshot exists, the first one is to be created from the event log starting at the beginning.

-}
checkAgainstCurrentSnapshot :
    SnapshotChannel a
    -> SnapshotEvent
    -> { cache : Dict String (Snapshot Value) }
    -> Procedure.Procedure ErrorFormat SnapshotCondition Msg
checkAgainstCurrentSnapshot component event state =
    Procedure.provide state
        |> Procedure.andThen (getLatestSnapshotFromCache component event)
        |> Procedure.andThen
            (\{ cache, maybeLatest } ->
                case maybeLatest of
                    Just latest ->
                        if latest.seq >= event.seq then
                            Procedure.provide { cache = cache, maybeLatest = Just latest }

                        else
                            getLatestSnapshotFromTable component event { cache = state.cache }

                    Nothing ->
                        getLatestSnapshotFromTable component event { cache = state.cache }
            )
        |> Procedure.andThen
            (\{ cache, maybeLatest } ->
                case maybeLatest of
                    Just latest ->
                        if latest.seq >= event.seq then
                            Procedure.provide (LaterFound (Dict.insert event.channel latest cache))

                        else
                            Procedure.provide (OutOfDate latest)

                    Nothing ->
                        Procedure.provide New
            )


{-| Describes the possible outcomes of checking the state of the current snapshot.
-}
type SnapshotCondition
    = LaterFound (Dict String (Snapshot Value))
    | OutOfDate (Snapshot Value)
    | New


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
    Apis.snapshotTableApi.query query
        |> Procedure.fetchResult
        |> Procedure.mapError Dynamo.errorToDetails
        |> Procedure.map
            (\queryResult ->
                case queryResult of
                    [] ->
                        { cache = state.cache, maybeLatest = Nothing }

                    r :: _ ->
                        { cache = state.cache, maybeLatest = Just { seq = r.seq, model = r.snapshot } }
            )


readLaterEvents :
    SnapshotChannel a
    -> SnapshotEvent
    ->
        { cache : Dict String (Snapshot Value)
        , baseSnapshot : Maybe (Snapshot Value)
        }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , baseSnapshot : Maybe (Snapshot Value)
            , laterEvents : List EventLog.Record
            }
            Msg
readLaterEvents component event state =
    let
        seq =
            Maybe.map .seq state.baseSnapshot
                |> Maybe.withDefault 0

        matchLaterEvents =
            Dynamo.partitionKeyEquals "id" event.channel
                |> Dynamo.rangeKeyGreaterThan "seq" (Dynamo.int seq)
                |> Dynamo.orderResults Forward

        query =
            { tableName = component.eventLogTable
            , match = matchLaterEvents
            }
    in
    Apis.eventLogTableApi.query query
        |> Procedure.fetchResult
        |> Procedure.mapError Dynamo.errorToDetails
        |> Procedure.map
            (\laterEvents ->
                { cache = state.cache
                , baseSnapshot = state.baseSnapshot
                , laterEvents = laterEvents
                }
            )


saveNextSnapshot :
    SnapshotChannel a
    -> SnapshotEvent
    ->
        { cache : Dict String (Snapshot Value)
        , baseSnapshot : Maybe (Snapshot Value)
        , laterEvents : List EventLog.Record
        }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            }
            Msg
saveNextSnapshot component event state =
    let
        nextSnapshot =
            { seq = 0, model = Encode.null }
    in
    Procedure.fromTask Time.now
        |> Procedure.andThen
            (\timestamp ->
                Apis.snapshotTableApi.put
                    { tableName = component.snapshotTable
                    , item =
                        { id = event.channel
                        , seq = nextSnapshot.seq
                        , updatedAt = timestamp
                        , snapshot = nextSnapshot.model
                        }
                    }
                    |> Procedure.fetchResult
                    |> Procedure.mapError Dynamo.errorToDetails
                    |> Procedure.map (\_ -> { cache = Dict.insert event.channel nextSnapshot state.cache })
            )
