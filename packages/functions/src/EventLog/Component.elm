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

import AWS.Dynamo as Dynamo
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
                |> Procedure.andThen (getEventsLogMetaData component channelName)
                |> Procedure.andThen (readEvents component channelName)
                |> Procedure.andThen (recordEventsAndMetadata component channelName)
                |> Procedure.andThen (publishEvents component channelName)
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


getEventsLogMetaData :
    Component a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat { sessionKey : MomentoSessionKey, lastSeqNo : Int } Msg
getEventsLogMetaData component channelName sessionKey =
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
                        { sessionKey = sessionKey, lastSeqNo = metadata.lastId } |> Procedure.provide

                    Nothing ->
                        { message = "No EventLog metadata record found for channel: " ++ channelName
                        , details = Encode.null
                        }
                            |> Procedure.break
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


readEvents :
    Component a
    -> String
    -> { sessionKey : MomentoSessionKey, lastSeqNo : Int }
    ->
        Procedure.Procedure ErrorFormat
            { sessionKey : MomentoSessionKey
            , lastSeqNo : Int
            , cacheItem : UnsavedEvent
            }
            Msg
readEvents component channelName state =
    momentoApi.popList
        state.sessionKey
        { list = saveListName channelName
        }
        |> Procedure.fetchResult
        |> Procedure.mapError Momento.errorToDetails
        |> Procedure.andThen
            (\cacheItem ->
                case Decode.decodeValue decodeUnsavedEvent cacheItem.payload of
                    Ok unsavedEvent ->
                        { sessionKey = state.sessionKey
                        , lastSeqNo = state.lastSeqNo
                        , cacheItem = unsavedEvent
                        }
                            |> Procedure.provide

                    Err _ ->
                        { message = "No EventLog metadata record found for channel: " ++ channelName
                        , details = Encode.null
                        }
                            |> Procedure.break
            )


{-| Records the event in the event log table AND updates the metadata so that the sequence number is bumped
by one. If more than one process attempts to do this at the same time, it can fail because the sequence
number is already taken. In that case the operation is retried until it succeeds and a unique sequence
number is assigned to the event.
-}
recordEventsAndMetadata :
    Component a
    -> String
    ->
        { sessionKey : MomentoSessionKey
        , lastSeqNo : Int
        , cacheItem : UnsavedEvent
        }
    ->
        Procedure.Procedure ErrorFormat
            { sessionKey : MomentoSessionKey
            , lastSeqNo : Int
            , cacheItem : UnsavedEvent
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
                        , event = state.cacheItem.payload
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
                    --eventLogTableMetadataApi.update
                    --    { tableName = component.eventLogTable
                    --    , key = { id = metadataKeyName channelName, seq = 0 }
                    --    , updateExpression = "SET lastId = lastId + :incr"
                    --    , conditionExpression = Just "lastId = :current_id"
                    --    , expressionAttributeNames = Dict.empty
                    --    , expressionAttributeValues =
                    --        [ ( ":incr", Dynamo.int 1 )
                    --        , ( ":current_id", Dynamo.int state.lastSeqNo )
                    --        ]
                    --            |> Dict.fromList
                    --    , returnConsumedCapacity = Nothing
                    --    , returnItemCollectionMetrics = Nothing
                    --    , returnValues = Nothing
                    --    , returnValuesOnConditionCheckFailure = Nothing
                    --    }
                    --    |> Procedure.fetchResult
                    --    |> Procedure.map (always state)
                    --    |> Procedure.mapError Dynamo.errorToDetails
                    --    |> Procedure.andThen
                    --        (\_ ->
                    --            eventLogTableApi.put
                    --                { tableName = component.eventLogTable
                    --                , item = eventRecord
                    --                }
                    |> Procedure.fetchResult
                    |> Procedure.map
                        (always
                            { sessionKey = state.sessionKey
                            , lastSeqNo = assignedSeqNo
                            , cacheItem = state.cacheItem
                            }
                        )
                    |> Procedure.mapError Dynamo.errorToDetails
             --        )
            )


publishEvents :
    Component a
    -> String
    ->
        { sessionKey : MomentoSessionKey
        , lastSeqNo : Int
        , cacheItem : UnsavedEvent
        }
    -> Procedure.Procedure ErrorFormat () Msg
publishEvents component channelName state =
    let
        payload =
            [ ( "rt", Encode.string "P" )
            , ( "client", Encode.string state.cacheItem.client )
            , ( "seq", Encode.int state.lastSeqNo )
            , ( "payload", state.cacheItem.payload )
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
