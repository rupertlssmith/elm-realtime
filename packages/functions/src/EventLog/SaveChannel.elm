module EventLog.SaveChannel exposing (saveChannel)

import AWS.Credentials exposing (Credentials)
import AWS.Dynamo as Dynamo exposing (Error(..))
import AWS.Http exposing (Error(..))
import AWS.Sqs as Sqs
import DB.EventLogTable as EventLogTable
import Dict
import ErrorFormat exposing (ErrorFormat)
import EventLog.Apis as Apis
import EventLog.Model exposing (Model(..), ReadyState)
import EventLog.Msg exposing (Msg(..))
import EventLog.OpenMomentoCache as OpenMomentoCache
import EventLog.Route exposing (Route)
import Http.Response as Response exposing (Response)
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Names
import Procedure
import Realtime exposing (UnsavedEvent)
import Time exposing (Posix)
import Update2 as U2


type alias SaveChannel a =
    { a
        | awsRegion : String
        , defaultCredentials : Credentials
        , momentoApiKey : String
        , eventLogTable : String
        , snapshotQueueUrl : String
        , eventLog : Model
    }


setModel : SaveChannel a -> Model -> SaveChannel a
setModel m x =
    { m | eventLog = x }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


type DrainState
    = DrainedNothing MomentoSessionKey
    | DrainedToSeq
        { sessionKey : MomentoSessionKey
        , lastSeqNo : Int
        }


{-| Channel save:

    * Obtain a connection to the cache.
    * Read the saved events from the cache list.
    * Save the events to the dynamodb event log.
    * Remove the saved events from the cache list.
    * Publish the saved event to the model topic.

-}
saveChannel :
    HttpSessionKey
    -> ReadyState
    -> ApiRequest Route
    -> String
    -> SaveChannel a
    -> ( SaveChannel a, Cmd Msg )
saveChannel session state apiRequest channelName component =
    let
        procedure : Procedure.Procedure Response Response Msg
        procedure =
            Procedure.provide channelName
                |> Procedure.andThen (OpenMomentoCache.openMomentoCache component)
                |> Procedure.andThen (drainSaveList component channelName)
                |> Procedure.andThen (notifyCompactor component channelName)
                |> Procedure.mapError (Debug.log "error" >> ErrorFormat.encodeErrorFormat >> Response.err500json)
                |> Procedure.map (Response.ok200json Encode.null |> always)
    in
    ( state
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)


{-| Pops a single event from the save list, saves it to the database with a unique and contiguous sequence
number, then repeats until there are no more events to pop from the save list.
-}
drainSaveList :
    SaveChannel a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat DrainState Msg
drainSaveList component channelName sessionKey =
    drainSaveListInner component channelName (DrainedNothing sessionKey)


drainSaveListInner :
    SaveChannel a
    -> String
    -> DrainState
    -> Procedure.Procedure ErrorFormat DrainState Msg
drainSaveListInner component channelName state =
    let
        msk =
            case state of
                DrainedNothing sessionKey ->
                    sessionKey

                DrainedToSeq { sessionKey } ->
                    sessionKey
    in
    Procedure.provide msk
        |> Procedure.andThen (tryReadEvent component channelName)
        |> Procedure.andThen
            (\innerState ->
                case innerState.unsavedEvent of
                    Nothing ->
                        Procedure.provide state

                    Just event ->
                        Procedure.provide { sessionKey = msk, unsavedEvent = event }
                            |> Procedure.andThen (recordEventWithUniqueSeqNo component channelName)
                            |> Procedure.andThen (publishEvent component channelName)
                            |> Procedure.map
                                (\{ sessionKey, lastSeqNo } ->
                                    DrainedToSeq
                                        { sessionKey = sessionKey
                                        , lastSeqNo = lastSeqNo
                                        }
                                )
                            |> Procedure.andThen (drainSaveListInner component channelName)
            )


{-| Tries to pop one event from the save list. If no event can be found Nothing will be retured in the
`unsavedEvent` field. This is an expected condition and not an error.
-}
tryReadEvent :
    SaveChannel a
    -> String
    -> MomentoSessionKey
    ->
        Procedure.Procedure ErrorFormat
            { sessionKey : MomentoSessionKey
            , unsavedEvent : Maybe UnsavedEvent
            }
            Msg
tryReadEvent component channelName sessionKey =
    Apis.momentoApi.popList
        sessionKey
        { list = Names.saveListName channelName
        }
        |> Procedure.fetchResult
        |> Procedure.mapError Momento.errorToDetails
        |> Procedure.andThen
            (\maybeCacheItem ->
                case maybeCacheItem of
                    Just cacheItem ->
                        case Decode.decodeValue Realtime.unsavedEventDecoder cacheItem.payload of
                            Ok unsavedEvent ->
                                { sessionKey = sessionKey
                                , unsavedEvent = Just unsavedEvent
                                }
                                    |> Procedure.provide

                            Err err ->
                                { message = Decode.errorToString err
                                , details = Encode.null
                                }
                                    |> Procedure.break

                    Nothing ->
                        { sessionKey = sessionKey
                        , unsavedEvent = Nothing
                        }
                            |> Procedure.provide
            )


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
    SaveChannel a
    -> String
    ->
        { sessionKey : MomentoSessionKey
        , unsavedEvent : UnsavedEvent
        }
    ->
        Procedure.Procedure ErrorFormat
            { sessionKey : MomentoSessionKey
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
                        { sessionKey = stateAfterTxAttempt.sessionKey
                        , unsavedEvent = stateAfterTxAttempt.unsavedEvent
                        }
            )


{-| Fetches the event log metadata for the channel. This provides the last event sequence number stored
for that channel. This can be bumped by one to get the next sequence number, but this will be optimistic -
another process could get the same number.
-}
getEventsLogMetaData :
    SaveChannel a
    -> String
    ->
        { sessionKey : MomentoSessionKey
        , unsavedEvent : UnsavedEvent
        }
    ->
        Procedure.Procedure ErrorFormat
            { sessionKey : MomentoSessionKey
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
                        { sessionKey = state.sessionKey
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
    SaveChannel a
    -> String
    ->
        { sessionKey : MomentoSessionKey
        , lastSeqNo : Int
        , unsavedEvent : UnsavedEvent
        }
    ->
        Procedure.Procedure ErrorFormat
            { sessionKey : MomentoSessionKey
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
                            { sessionKey = state.sessionKey
                            , lastSeqNo = assignedSeqNo
                            , txSuccess = True
                            , unsavedEvent = state.unsavedEvent
                            }
                        )
                    |> Procedure.catch
                        (\error ->
                            case error of
                                ConditionCheckFailed _ ->
                                    { sessionKey = state.sessionKey
                                    , lastSeqNo = assignedSeqNo
                                    , txSuccess = False
                                    , unsavedEvent = state.unsavedEvent
                                    }
                                        |> Procedure.provide

                                _ ->
                                    Dynamo.errorToDetails error |> Procedure.break
                        )
            )


publishEvent :
    SaveChannel a
    -> String
    ->
        { x
            | sessionKey : MomentoSessionKey
            , lastSeqNo : Int
            , unsavedEvent : UnsavedEvent
        }
    ->
        Procedure.Procedure ErrorFormat
            { x
                | sessionKey : MomentoSessionKey
                , lastSeqNo : Int
                , unsavedEvent : UnsavedEvent
            }
            Msg
publishEvent component channelName state =
    let
        payload =
            [ ( "rt", Encode.string "P" )
            , ( "client", Encode.string state.unsavedEvent.client )
            , ( "seq", Encode.int state.lastSeqNo )
            , ( "payload", state.unsavedEvent.payload )
            ]
                |> Encode.object
    in
    Apis.momentoApi.publish
        state.sessionKey
        { topic = Names.modelTopicName channelName
        , payload = payload
        }
        |> Procedure.fetchResult
        |> Procedure.map (always state)
        |> Procedure.mapError Momento.errorToDetails


notifyCompactor :
    SaveChannel a
    -> String
    -> DrainState
    -> Procedure.Procedure ErrorFormat () Msg
notifyCompactor component channelName drainState =
    case drainState of
        DrainedNothing _ ->
            Procedure.provide ()

        DrainedToSeq { lastSeqNo } ->
            let
                request =
                    Realtime.encodeSnapshotEvent channelName lastSeqNo
                        |> Encode.encode 2

                sqsMessage =
                    Sqs.sendMessage
                        { delaySeconds = Nothing
                        , messageAttributes = Nothing
                        , messageBody = request
                        , messageDeduplicationId = channelName ++ ":" ++ String.fromInt lastSeqNo |> Just
                        , messageGroupId = Just channelName
                        , messageSystemAttributes = Nothing
                        , queueUrl = component.snapshotQueueUrl
                        }

                notifyCmd =
                    sqsMessage
                        |> AWS.Http.send (Sqs.service component.awsRegion) component.defaultCredentials
            in
            Procedure.fromTask notifyCmd
                |> Procedure.mapError awsErrorToDetails
                |> Procedure.map (always ())


awsErrorToDetails : AWS.Http.Error AWS.Http.AWSAppError -> ErrorFormat
awsErrorToDetails err =
    case err of
        HttpError hterr ->
            { message = "Http.Error: " ++ Debug.toString hterr, details = Encode.null }

        AWSError awserr ->
            { message = "AWSError: " ++ awserr.type_ ++ " " ++ (awserr.message |> Maybe.withDefault "")
            , details = Encode.null
            }


{-| Decide whether to trigger a compaction notification based on the timestamp of the last compaction
and the latest sequence number written.

It is expected that compaction will happen every X sequence numbers, or if a compaction has not been
done for Y seconds.

-}
compactionTrigger : Posix -> Posix -> Int -> Bool
compactionTrigger prev latest seq =
    True
