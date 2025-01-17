module EventLog.SnapshotChannel exposing
    ( SnapshotChannel
    , procedure
    )

import AWS.Credentials exposing (Credentials)
import AWS.Dynamo as Dynamo exposing (Error(..), Order(..))
import DB.EventLogTable as EventLog
import Dict exposing (Dict)
import ErrorFormat exposing (ErrorFormat)
import EventLog.Apis as Apis
import EventLog.LatestSnapshot as LatestSnapshot
import EventLog.Model exposing (Model(..), ReadyState)
import EventLog.Msg exposing (Msg(..))
import Http.Response as Response exposing (Response)
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Procedure
import Realtime exposing (RTMessage(..), Snapshot, SnapshotRequestEvent)
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
        , eventLog : Model
    }


setModel : SnapshotChannel a -> Model -> SnapshotChannel a
setModel m x =
    { m | eventLog = x }


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
        _ =
            Debug.log "SnapshotChannel.procedure" "called"

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
                    Decode.decodeString Realtime.snapshotRequestEventDecoder sqsMessage.body
                        |> Result.map
                            (\snapshotRequestEvent ->
                                Dict.update
                                    snapshotRequestEvent.channel
                                    (updateHighest snapshotRequestEvent)
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



--======


type DrainState
    = DrainedNothing (Dict String (Snapshot Value))
    | DrainedToSeq
        { cache : Dict String (Snapshot Value)
        , lastSeqNo : Int
        }


drainSnapshotRequests :
    SnapshotChannel a
    -> List SnapshotRequestEvent
    -> { cache : Dict String (Snapshot Value) }
    -> Procedure.Procedure ErrorFormat DrainState Msg
drainSnapshotRequests component snapshotSeqByChannel state =
    drainSnapshotRequestsInner component snapshotSeqByChannel (DrainedNothing state.cache)


drainSnapshotRequestsInner :
    SnapshotChannel a
    -> List SnapshotRequestEvent
    -> DrainState
    -> Procedure.Procedure ErrorFormat DrainState Msg
drainSnapshotRequestsInner component snapshotSeqByChannel state =
    let
        _ =
            Debug.log "SnapshotChannel.drainSnapshotRequests" "called"
    in
    case snapshotSeqByChannel of
        [] ->
            Procedure.provide state

        snapshotRequestEvent :: events ->
            Procedure.provide state
                |> Procedure.andThen (snapshotChannel component snapshotRequestEvent)
                |> Procedure.andThen (drainSnapshotRequestsInner component events)


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
    -> SnapshotRequestEvent
    -> { cache : Dict String (Snapshot Value) }
    -> Procedure.Procedure ErrorFormat { cache : Dict String (Snapshot Value) } Msg
snapshotChannel component event state =
    let
        _ =
            Debug.log "SnapshotChannel.snapshotChannel" "called"
    in
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
    -> SnapshotRequestEvent
    -> { cache : Dict String (Snapshot Value) }
    -> Procedure.Procedure ErrorFormat SnapshotCondition Msg
checkAgainstCurrentSnapshot component event state =
    let
        _ =
            Debug.log "SnapshotChannel.checkAgainstCurrentSnapshot" "called"
    in
    Procedure.provide state
        |> Procedure.andThen
            (LatestSnapshot.getLatestSnapshotFromCache
                component
                event.channel
            )
        |> Procedure.andThen
            (\{ cache, maybeLatest } ->
                case maybeLatest of
                    Just latest ->
                        if latest.seq >= event.seq then
                            Procedure.provide { cache = cache, maybeLatest = Just latest }

                        else
                            LatestSnapshot.getLatestSnapshotFromTable
                                component
                                event.channel
                                { cache = state.cache }

                    Nothing ->
                        LatestSnapshot.getLatestSnapshotFromTable
                            component
                            event.channel
                            { cache = state.cache }
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


readLaterEvents :
    SnapshotChannel a
    -> SnapshotRequestEvent
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
        _ =
            Debug.log "SnapshotChannel.readLaterEvents" "called"

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


{-| TODO: Change this to record the latest snapshot sequence number in a metadata row, the same way it is done
in SnapshotChannel. This will allow the latest value to be retrieved efficiently, since reverse and limit to 1 with
partition key equality check does not seem to work in Dynamo.
-}
saveNextSnapshot :
    SnapshotChannel a
    -> SnapshotRequestEvent
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
        _ =
            Debug.log "SnapshotChannel.saveNextSnapshot" "called"

        rtMessage record =
            RTPersisted record.seq record.event

        maybeNextSnapshot =
            List.foldl
                (\rtm acc ->
                    case acc of
                        Nothing ->
                            initialSnapshot rtm

                        Just prev ->
                            stepSnapshot rtm prev |> Just
                )
                state.baseSnapshot
                (List.map rtMessage state.laterEvents)
    in
    case maybeNextSnapshot of
        Just nextSnapshot ->
            Procedure.fromTask Time.now
                |> Procedure.andThen
                    (\timestamp ->
                        (Apis.snapshotTableApi component.snapshotTable).put
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

        Nothing ->
            Procedure.provide { cache = state.cache }


{-| Runs a loop of attempts to store the event against a unique and contiguous sequence number at the end
of the event log, until this completes successfuly.

    1. The assigned sequence number is created optimistically by adding one to the last value stored. More
       than one process can end up with the same number because of this.

    2. The event and the plus oned sequence number are written as a transaction with conditions to check
       that the sequence number has not been updated by another process.

    3. If the transaction fails due to the condition check not passing, the process goes back to step 1
       and tries again, until it does pass.

-}
recordEventWithUniqueSeqNo :
    SnapshotChannel a
    -> String
    ->
        { cache : Dict String (Snapshot Value)
        , unsavedEvent : UnsavedEvent
        }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , lastSeqNo : Int
            , txSuccess : Bool
            , unsavedEvent : UnsavedEvent
            }
            Msg
recordEventWithUniqueSeqNo component channelName state =
    Procedure.provide state
        |> Procedure.andThen (getEventsLogMetaData component channelName)
        |> Procedure.andThen (recordEventsAndMetadata component channelName)
        |> Procedure.andThen
            (\stateAfterTxAttempt ->
                if stateAfterTxAttempt.txSuccess then
                    Procedure.provide stateAfterTxAttempt

                else
                    recordEventWithUniqueSeqNo component
                        channelName
                        { cache = stateAfterTxAttempt.cache
                        , unsavedEvent = stateAfterTxAttempt.unsavedEvent
                        }
            )


{-| Fetches the event log metadata for the channel. This provides the last event sequence number stored
for that channel. This can be bumped by one to get the next sequence number, but this will be optimistic -
another process could get the same number.
-}
getEventsLogMetaData :
    SnapshotChannel a
    -> String
    ->
        { cache : Dict String (Snapshot Value)
        , unsavedEvent : UnsavedEvent
        }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , unsavedEvent : UnsavedEvent
            , lastSeqNo : Int
            }
            Msg
getEventsLogMetaData component channelName state =
    let
        key =
            { id = Names.metadataKeyName channelName
            , seq = 0
            }
    in
    Apis.eventLogTableMetadataApi.get
        { tableName = component.eventLogTable
        , key = key
        }
        |> Procedure.fetchResult
        |> Procedure.mapError Dynamo.errorToDetails
        |> Procedure.andThen
            (\maybeMetaData ->
                case maybeMetaData of
                    Just metadata ->
                        { cache = state.cache
                        , unsavedEvent = state.unsavedEvent
                        , lastSeqNo = metadata.lastId
                        }
                            |> Procedure.provide

                    Nothing ->
                        { message = "No EventLog metadata record found for channel: " ++ channelName
                        , details = Encode.null
                        }
                            |> Procedure.break
            )


{-| Records the event in the event log table AND updates the metadata in a write transaction so that the
sequence number is bumped by one.

If more than one process attempts to do this at the same time, it can fail because the sequence number is
already taken. If the transaction fails to write the `txSuccess` flag returned will be `False`.

-}
recordEventsAndMetadata :
    SnapshotChannel a
    -> String
    ->
        { cache : Dict String (Snapshot Value)
        , lastSeqNo : Int
        , unsavedEvent : UnsavedEvent
        }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , lastSeqNo : Int
            , txSuccess : Bool
            , unsavedEvent : UnsavedEvent
            }
            Msg
recordEventsAndMetadata component channelName state =
    Procedure.fromTask Time.now
        |> Procedure.andThen
            (\timestamp ->
                let
                    assignedSeqNo =
                        state.lastSeqNo + 1

                    eventRecord =
                        { id = channelName
                        , seq = assignedSeqNo
                        , updatedAt = timestamp
                        , event = state.unsavedEvent.payload
                        }

                    seqUpdate =
                        Dynamo.updateCommand
                            EventLogTable.encodeKey
                            { tableName = component.eventLogTable
                            , key = { id = Names.metadataKeyName channelName, seq = 0 }
                            , updateExpression = "SET lastId = lastId + :incr"
                            , conditionExpression = Just "lastId = :current_id"
                            , expressionAttributeNames = Dict.empty
                            , expressionAttributeValues =
                                [ ( ":incr", Dynamo.int 1 )
                                , ( ":current_id", Dynamo.int state.lastSeqNo )
                                ]
                                    |> Dict.fromList
                            , returnConsumedCapacity = Nothing
                            , returnItemCollectionMetrics = Nothing
                            , returnValues = Nothing
                            , returnValuesOnConditionCheckFailure = Nothing
                            }

                    eventPut =
                        Dynamo.putCommand
                            EventLogTable.encodeRecord
                            { tableName = component.eventLogTable
                            , item = eventRecord
                            }
                in
                Apis.eventLogTableMetadataApi.writeTx
                    { tableName = component.eventLogTable
                    , commands = [ seqUpdate, eventPut ]
                    }
                    |> Procedure.fetchResult
                    |> Procedure.map
                        (always
                            { cache = state.cache
                            , lastSeqNo = assignedSeqNo
                            , txSuccess = True
                            , unsavedEvent = state.unsavedEvent
                            }
                        )
                    |> Procedure.catch
                        (\error ->
                            case error of
                                ConditionCheckFailed _ ->
                                    { cache = state.cache
                                    , lastSeqNo = assignedSeqNo
                                    , txSuccess = False
                                    , unsavedEvent = state.unsavedEvent
                                    }
                                        |> Procedure.provide

                                _ ->
                                    Dynamo.errorToDetails error |> Procedure.break
                        )
            )



-- Quick and dirty snapshot functions...


initialSnapshot : RTMessage -> Maybe (Snapshot Value)
initialSnapshot rtmessage =
    case rtmessage of
        RTPersisted seq val ->
            { seq = seq
            , model = "hello-" ++ String.fromInt seq |> Encode.string
            }
                |> Just

        RTTransient _ ->
            Nothing

        RTSnapshot seq val ->
            { seq = seq
            , model = val
            }
                |> Just


stepSnapshot : RTMessage -> Snapshot Value -> Snapshot Value
stepSnapshot rtmessage current =
    case rtmessage of
        RTPersisted seq val ->
            { seq = seq
            , model = "hello-" ++ String.fromInt seq |> Encode.string
            }

        RTTransient _ ->
            current

        RTSnapshot seq val ->
            { seq = seq
            , model = val
            }
