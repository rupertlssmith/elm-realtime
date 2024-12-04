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
import Json.Decode exposing (Value)
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


{-| Channel creation:

    * Take the first available channel from the database of channels.
    * Confirm the cache and webhooks for it exists in momento.
    * Mark the channel as allocated in the database.
    * Return a confirmation that everything has been set up.

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
    * Create a dynamodb table for the persisted events or confirm it already exists.
    * Create a webhook on the save topic.
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
                |> Procedure.andThen (recordChannelToDB component channelName)
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


recordChannelToDB :
    Component a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat ChannelTable.Record Msg
recordChannelToDB component channelName sessionKey =
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
                |> Procedure.andThen (readEvents component channelName)
                |> Procedure.andThen (recordEventsToDB component channelName)
                |> Procedure.andThen (publishEvents component channelName)
                |> Procedure.mapError (encodeErrorFormat >> Response.err500json)
                |> Procedure.map (Response.ok200json Encode.null |> always)
    in
    ( state
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)
        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
        |> protocol.onUpdate


readEvents :
    Component a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat ( MomentoSessionKey, CacheItem ) Msg
readEvents component channelName sessionKey =
    momentoApi.popList
        sessionKey
        { list = saveListName channelName
        }
        |> Procedure.fetchResult
        |> Procedure.map (Tuple.pair sessionKey)
        |> Procedure.mapError Momento.errorToDetails


recordEventsToDB :
    Component a
    -> String
    -> ( MomentoSessionKey, CacheItem )
    -> Procedure.Procedure ErrorFormat ( MomentoSessionKey, CacheItem ) Msg
recordEventsToDB component channelName ( sessionKey, cacheItem ) =
    Procedure.fromTask Time.now
        |> Procedure.andThen
            (\timestamp ->
                let
                    eventRecord =
                        { id = channelName
                        , seq = 0
                        , updatedAt = timestamp
                        , event = cacheItem.payload
                        }
                in
                eventLogTableApi.put
                    { tableName = component.eventLogTable
                    , item = eventRecord
                    }
                    |> Procedure.fetchResult
                    |> Procedure.map (always ( sessionKey, cacheItem ))
                    |> Procedure.mapError Dynamo.errorToDetails
            )


publishEvents :
    Component a
    -> String
    -> ( MomentoSessionKey, CacheItem )
    -> Procedure.Procedure ErrorFormat () Msg
publishEvents component channelName ( sessionKey, cacheItem ) =
    momentoApi.publish
        sessionKey
        { topic = modelTopicName channelName
        , payload = cacheItem.payload
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
