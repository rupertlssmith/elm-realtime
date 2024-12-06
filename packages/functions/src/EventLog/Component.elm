module EventLog.Component exposing
    ( Component
    , Model(..)
    , Msg
    , Protocol
    , init
    , subscriptions
    , update
    )

{-| API for managing realtime channels.
-}

import AWS.Dynamo as Dynamo exposing (Error(..))
import Codec
import DB.ChannelTable as ChannelTable
import DB.EventLogTable as EventLogTable
import Dict
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Extra as DE
import Json.Encode as Encode
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Ports
import Procedure
import Procedure.Program
import Random
import Random.Char
import Random.String
import Result.Extra
import Serverless.HttpServer as HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Serverless.Request as Request exposing (Method(..))
import Serverless.Response as Response exposing (Response)
import Time
import Update2 as U2
import Url exposing (Url)
import Url.Parser as UP exposing ((</>), (<?>))


type alias Component a =
    { a
        | momentoApiKey : String
        , channelApiUrl : String
        , channelTable : String
        , eventLogTable : String
        , eventLog : Model
    }


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | RandomSeed Random.Seed
    | HttpRequest HttpSessionKey (Result HttpServer.Error (ApiRequest Route))
    | HttpResponse HttpSessionKey (Result Response Response)
    | MomentoError Momento.Error


type Model
    = ModelStart StartState
    | ModelReady ReadyState


type alias StartState =
    {}


type alias ReadyState =
    { seed : Random.Seed
    , procedure : Procedure.Program.Model Msg
    }


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    U2.pure {}
        |> U2.andMap randomize
        |> U2.andMap (switchState ModelStart)
        |> Tuple.mapSecond (Cmd.map toMsg)


subscriptions : Protocol (Component a) msg model -> Component a -> Sub msg
subscriptions protocol component =
    let
        model =
            component.eventLog
    in
    case model of
        ModelReady state ->
            [ Procedure.Program.subscriptions state.procedure
            , httpServerApi.request HttpRequest
            , momentoApi.asyncError MomentoError
            ]
                |> Sub.batch
                |> Sub.map protocol.toMsg

        _ ->
            Sub.none


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.eventLog
    in
    case ( model, msg ) of
        ( ModelStart _, RandomSeed seed ) ->
            { seed = seed
            , procedure = Procedure.Program.init
            }
                |> U2.pure
                |> U2.andMap (switchState ModelReady)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelReady state, ProcedureMsg innerMsg ) ->
            let
                ( procMdl, procMsg ) =
                    Procedure.Program.update innerMsg state.procedure
            in
            ( { state | procedure = procMdl }, procMsg )
                |> U2.andMap (switchState ModelReady)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelReady state, HttpRequest session result ) ->
            case result of
                Ok apiRequest ->
                    processRoute protocol session apiRequest component

                Err httpError ->
                    ( ModelReady state
                    , httpError
                        |> HttpServer.errorToString
                        |> Response.err500
                        |> httpServerApi.response session
                    )
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate

        ( _, HttpResponse session result ) ->
            ( component
            , result |> Result.Extra.merge |> httpServerApi.response session
            )
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( _, MomentoError error ) ->
            U2.pure component
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate


setModel : Component a -> Model -> Component a
setModel m x =
    { m | eventLog = x }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


randomize : StartState -> ( StartState, Cmd Msg )
randomize model =
    ( model
    , Random.generate RandomSeed Random.independentSeed
    )



-- Connect Stateless APIs to their Ports


dynamoPorts : Dynamo.Ports Msg
dynamoPorts =
    { get = Ports.dynamoGet
    , put = Ports.dynamoPut
    , update = Ports.dynamoUpdate
    , writeTx = Ports.dynamoWriteTx
    , delete = Ports.dynamoDelete
    , batchGet = Ports.dynamoBatchGet
    , batchWrite = Ports.dynamoBatchWrite
    , scan = Ports.dynamoScan
    , query = Ports.dynamoQuery
    , response = Ports.dynamoResponse
    }


channelTableApi : Dynamo.DynamoTypedApi ChannelTable.Key ChannelTable.Record Msg
channelTableApi =
    ChannelTable.operations ProcedureMsg dynamoPorts


eventLogTableApi : Dynamo.DynamoTypedApi EventLogTable.Key EventLogTable.Record Msg
eventLogTableApi =
    EventLogTable.operations ProcedureMsg dynamoPorts


eventLogTableMetadataApi : Dynamo.DynamoTypedApi EventLogTable.Key EventLogTable.MetadataRecord Msg
eventLogTableMetadataApi =
    EventLogTable.metadataOperations ProcedureMsg dynamoPorts


momentoApi : Momento.MomentoApi Msg
momentoApi =
    { open = Ports.mmOpen
    , close = Ports.mmClose
    , subscribe = Ports.mmSubscribe
    , publish = Ports.mmPublish
    , onMessage = Ports.mmOnMessage
    , pushList = Ports.mmPushList
    , popList = Ports.mmPopList
    , createWebhook = Ports.mmCreateWebhook
    , response = Ports.mmResponse
    , asyncError = Ports.mmAsyncError
    }
        |> Momento.momentoApi ProcedureMsg


httpServerApi : HttpServer.HttpServerApi Msg Route
httpServerApi =
    { ports =
        { request = Ports.requestPort
        , response = Ports.responsePort
        }
    , parseRoute = routeParser
    }
        |> HttpServer.httpServerApi



-- API Routing


type Route
    = ChannelRoot
    | Channel String


routeParser : Url -> Maybe Route
routeParser =
    UP.oneOf
        [ UP.map ChannelRoot (UP.s "channel")
        , UP.map Channel (UP.s "channel" </> UP.string)
        ]
        |> UP.parse


processRoute : Protocol (Component a) msg model -> HttpSessionKey -> ApiRequest Route -> Component a -> ( model, Cmd msg )
processRoute protocol session apiRequest component =
    let
        model =
            component.eventLog
    in
    case ( Request.method apiRequest.request, apiRequest.route, model ) of
        ( GET, ChannelRoot, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (tryGetAvailableChannel protocol session state)

        ( POST, ChannelRoot, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (createChannel protocol session state)

        ( POST, Channel channelName, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (processSaveChannel protocol session state apiRequest channelName)

        _ ->
            U2.pure component
                |> protocol.onUpdate



-- Try and get the connection details of an available channel


{-| Look for an available channel.
-}
tryGetAvailableChannel : Protocol (Component a) msg model -> HttpSessionKey -> ReadyState -> Component a -> ( model, Cmd msg )
tryGetAvailableChannel protocol session state component =
    let
        procedure : Procedure.Procedure Response Response Msg
        procedure =
            Procedure.provide ()
                |> Procedure.andThen (findAvailableChannel component)
                |> Procedure.mapError (encodeErrorFormat >> Response.err500json)
                |> Procedure.map
                    (\maybeChannel ->
                        case maybeChannel of
                            Just channel ->
                                Response.ok200json (channel |> Codec.encoder ChannelTable.recordCodec)

                            Nothing ->
                                Response.notFound400json Encode.null
                    )
    in
    ( { seed = state.seed
      , procedure = state.procedure
      }
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)
        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
        |> protocol.onUpdate


findAvailableChannel :
    Component a
    -> ()
    -> Procedure.Procedure ErrorFormat (Maybe ChannelTable.Record) Msg
findAvailableChannel component _ =
    channelTableApi.scan
        { tableName = component.channelTable
        , exclusiveStartKey = Nothing
        }
        |> Procedure.fetchResult
        |> Procedure.map List.head
        |> Procedure.mapError Dynamo.errorToDetails



-- Create a new realtime channel


{-| Channel creation:

    * Create the cache or confirm it already exists.
    * Create a webhook on the save topic.
    * Create the meta-data record for the channel in the events table.
    * Record the channel information in the channels table.
    * Return a confirmation that everything has been set up.

-}
createChannel : Protocol (Component a) msg model -> HttpSessionKey -> ReadyState -> Component a -> ( model, Cmd msg )
createChannel protocol session state component =
    let
        ( channelName, nextSeed ) =
            Random.step nameGenerator state.seed

        procedure : Procedure.Procedure Response Response Msg
        procedure =
            Procedure.provide channelName
                |> Procedure.andThen (openMomentoCache component)
                |> Procedure.andThen (setupChannelWebhook component channelName)
                |> Procedure.andThen (recordEventsLogMetaData component channelName)
                |> Procedure.andThen (recordChannel component channelName)
                |> Procedure.mapError (encodeErrorFormat >> Response.err500json)
                |> Procedure.map (Codec.encoder ChannelTable.recordCodec >> Response.ok200json)
    in
    ( { seed = nextSeed
      , procedure = state.procedure
      }
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)
        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
        |> protocol.onUpdate


type alias ErrorFormat =
    { message : String
    , details : Value
    }


encodeErrorFormat : ErrorFormat -> Value
encodeErrorFormat error =
    [ ( "message", Encode.string error.message )
    , ( "details", error.details )
    ]
        |> Encode.object


setupChannelWebhook :
    Component a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat MomentoSessionKey Msg
setupChannelWebhook component channelName sessionKey =
    momentoApi.webhook
        sessionKey
        { name = webhookName channelName
        , topic = notifyTopicName channelName
        , url = component.channelApiUrl ++ "/v1/channel/" ++ channelName
        }
        |> Procedure.fetchResult
        |> Procedure.mapError Momento.errorToDetails


recordEventsLogMetaData :
    Component a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat MomentoSessionKey Msg
recordEventsLogMetaData component channelName sessionKey =
    Procedure.fromTask Time.now
        |> Procedure.andThen
            (\timestamp ->
                let
                    metadataRecord =
                        { id = metadataKeyName channelName
                        , seq = 0
                        , updatedAt = timestamp
                        , lastId = 0
                        }
                in
                eventLogTableMetadataApi.put
                    { tableName = component.eventLogTable
                    , item = metadataRecord
                    }
                    |> Procedure.fetchResult
                    |> Procedure.map (always sessionKey)
                    |> Procedure.mapError Dynamo.errorToDetails
            )


recordChannel :
    Component a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat ChannelTable.Record Msg
recordChannel component channelName sessionKey =
    Procedure.fromTask Time.now
        |> Procedure.andThen
            (\timestamp ->
                let
                    channelRecord =
                        { id = channelName
                        , updatedAt = timestamp
                        , modelTopic = modelTopicName channelName
                        , saveTopic = notifyTopicName channelName
                        , saveList = saveListName channelName
                        , webhook = webhookName channelName
                        }
                in
                channelTableApi.put
                    { tableName = component.channelTable
                    , item = channelRecord
                    }
                    |> Procedure.fetchResult
                    |> Procedure.map (always channelRecord)
                    |> Procedure.mapError Dynamo.errorToDetails
            )



-- Process a save channel notification.


{-| Channel save:

    * Obtain a connection to the cache.
    * Read the saved events from the cache list.
    * Save the events to the dynamodb event log.
    * Remove the saved events from the cache list.
    * Publish the saved event to the model topic.

    TODO: Use dynamoDB to auto increment the event seq no. This means having a separate table to hold the
    current top seq numbers, and updating it atomically:

    response = table.update_item(
        Key={'pk': 'orderCounter'},
        UpdateExpression="ADD #cnt :val",
        ExpressionAttributeNames={'#cnt': 'count'},
        ExpressionAttributeValues={':val': 1},
        ReturnValues="UPDATED_NEW"
    )

    Some kind of DSL for building update expressions needed?

    The write to increment the sequence and add the new event can also be done in a transaction:

    https://lucvandonkersgoed.com/2022/01/12/reliable-auto-incrementing-integers-in-dynamodb/

-}
processSaveChannel :
    Protocol (Component a) msg model
    -> HttpSessionKey
    -> ReadyState
    -> ApiRequest Route
    -> String
    -> Component a
    -> ( model, Cmd msg )
processSaveChannel protocol session state apiRequest channelName component =
    let
        procedure : Procedure.Procedure Response Response Msg
        procedure =
            Procedure.provide channelName
                |> Procedure.andThen (openMomentoCache component)
                |> Procedure.andThen (drainSaveList component channelName)
                |> Procedure.mapError (Debug.log "error" >> encodeErrorFormat >> Response.err500json)
                |> Procedure.map (Response.ok200json Encode.null |> always)
    in
    ( state
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)
        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
        |> protocol.onUpdate


{-| Pops a single event from the save list, saves it to the database with a unique and contiguous sequence
number, then repeats until there are no more events to pop from the save list.
-}
drainSaveList :
    Component a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat () Msg
drainSaveList component channelName sessionKey =
    Procedure.provide sessionKey
        |> Procedure.andThen (tryReadEvent component channelName)
        |> Procedure.andThen
            (\state ->
                case state.unsavedEvent of
                    Nothing ->
                        Procedure.provide ()

                    Just event ->
                        Procedure.provide { sessionKey = sessionKey, unsavedEvent = event }
                            |> Procedure.andThen (recordEventWithUniqueSeqNo component channelName)
                            |> Procedure.andThen (publishEvent component channelName)
                            |> Procedure.map (always sessionKey)
                            |> Procedure.andThen (drainSaveList component channelName)
            )


type alias UnsavedEvent =
    { rt : String
    , client : String
    , payload : Value
    }


decodeUnsavedEvent : Decoder UnsavedEvent
decodeUnsavedEvent =
    Decode.succeed UnsavedEvent
        |> DE.andMap (Decode.field "rt" Decode.string)
        |> DE.andMap (Decode.field "client" Decode.string)
        |> DE.andMap (Decode.field "payload" Decode.value)


{-| Tries to pop one event from the save list. If no event can be found Nothing will be retured in the
`unsavedEvent` field. This is an expected condition and not an error.
-}
tryReadEvent :
    Component a
    -> String
    -> MomentoSessionKey
    ->
        Procedure.Procedure ErrorFormat
            { sessionKey : MomentoSessionKey
            , unsavedEvent : Maybe UnsavedEvent
            }
            Msg
tryReadEvent component channelName sessionKey =
    momentoApi.popList
        sessionKey
        { list = saveListName channelName
        }
        |> Procedure.fetchResult
        |> Procedure.mapError Momento.errorToDetails
        |> Procedure.andThen
            (\maybeCacheItem ->
                case maybeCacheItem of
                    Just cacheItem ->
                        case Decode.decodeValue decodeUnsavedEvent cacheItem.payload of
                            Ok unsavedEvent ->
                                { sessionKey = sessionKey
                                , unsavedEvent = Just unsavedEvent
                                }
                                    |> Procedure.provide

                            Err _ ->
                                { message = "No EventLog metadata record found for channel: " ++ channelName
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
    Component a
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
    Component a
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
            { id = metadataKeyName channelName
            , seq = 0
            }
    in
    eventLogTableMetadataApi.get
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
    Component a
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
                            , key = { id = metadataKeyName channelName, seq = 0 }
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
                eventLogTableMetadataApi.writeTx
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
    Component a
    -> String
    ->
        { x
            | sessionKey : MomentoSessionKey
            , lastSeqNo : Int
            , unsavedEvent : UnsavedEvent
        }
    -> Procedure.Procedure ErrorFormat () Msg
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
    momentoApi.publish
        state.sessionKey
        { topic = modelTopicName channelName
        , payload = payload
        }
        |> Procedure.fetchResult
        |> Procedure.map (always ())
        |> Procedure.mapError Momento.errorToDetails



--


{-| Opens the named Momento cache and obtains a SessionKey to talk to it.
-}
openMomentoCache :
    Component a
    -> String
    -> Procedure.Procedure ErrorFormat MomentoSessionKey Msg
openMomentoCache component channelName =
    momentoApi.open
        { apiKey = component.momentoApiKey
        , cache = cacheName channelName
        }
        |> Procedure.fetchResult
        |> Procedure.mapError Momento.errorToDetails



--


nameGenerator : Random.Generator String
nameGenerator =
    Random.String.string 10 Random.Char.english


modelTopicName : String -> String
modelTopicName channel =
    channel ++ "-modeltopic"


notifyTopicName : String -> String
notifyTopicName channel =
    channel ++ "-savetopic"


cacheName : String -> String
cacheName channel =
    "elm-realtime" ++ "-cache"


saveListName : String -> String
saveListName channel =
    channel ++ "-savelist"


webhookName : String -> String
webhookName channel =
    channel ++ "-webhook"


metadataKeyName : String -> String
metadataKeyName channel =
    channel ++ "-metadata"
