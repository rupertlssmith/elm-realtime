module EventLog.Component exposing
    ( Component
    , Model(..)
    , Msg(..)
    , Protocol
    , ReadyState
    , Route(..)
    , StartState
    , cacheName
    , createChannel
    , init
    , modelTopicName
    , nameGenerator
    , notifyTopicName
    , processRoute
    , randomize
    , routeParser
    , saveChannelEvent
    , saveListName
    , setModel
    , subscriptions
    , switchState
    , update
    )

{-| API for managing realtime channels.
-}

import AWS.Dynamo as Dynamo
import Json.Encode as Encode
import Momento exposing (Error, Op(..), OpenParams, SessionKey)
import Ports
import Procedure
import Procedure.Program
import Random
import Random.Char
import Random.String
import Server.API exposing (ApiRoute)
import Serverless.Conn.Body as Body
import Serverless.Conn.Request as Request exposing (Method(..))
import Update2 as U2
import Url exposing (Url)
import Url.Parser as UP exposing ((</>), (<?>))


type alias Component a =
    { a
        | momentoApiKey : String
        , channelApiUrl : String
        , eventLog : Model
    }


setModel m x =
    { m | eventLog = x }


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    U2.pure {}
        |> U2.andMap randomize
        |> U2.andMap (switchState ModelStart)
        |> Tuple.mapSecond (Cmd.map toMsg)



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
        |> UP.map (Debug.log "route")
        |> UP.parse


processRoute : Protocol (Component a) msg model -> ApiRoute Route -> Component a -> ( model, Cmd msg )
processRoute protocol route component =
    let
        model =
            component.eventLog
    in
    case ( Request.method route.request, route.route, model ) |> Debug.log "processRoute" of
        ( GET, ChannelRoot, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (createChannel protocol route.route state)

        ( POST, ChannelRoot, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (createChannel protocol route.route state)

        ( POST, Channel _, ModelReady _ ) ->
            let
                _ =
                    Debug.log "EventLog.processRoute"
                        (Request.body route.request |> Body.asJson |> Result.map (Encode.encode 4))
            in
            U2.pure component
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate


{-| Channel creation:

    * Create the cache or confirm it already exists.
    * Create a dynamodb table for the persisted events or confirm it already exists.
    * Create a webhook on the save topic.
    * Return a confirmation that everything has been set up.

-}
createChannel : Protocol (Component a) msg model -> Route -> ReadyState -> Component a -> ( model, Cmd msg )
createChannel protocol route state component =
    let
        _ =
            Debug.log "createChannel" channelName

        ( channelName, nextSeed ) =
            Random.step nameGenerator state.seed

        procedure : Procedure.Procedure String () Msg
        procedure =
            Procedure.provide channelName
                |> Procedure.andThen (openMomentoCache component)
                |> Procedure.andThen recordChannelToDB
                |> Procedure.andThen (setupChannelWebhook component channelName)
    in
    ( { seed = nextSeed
      , procedure = state.procedure
      }
    , Procedure.try ProcedureMsg CreateChannelResponse procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)
        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
        |> protocol.onUpdate


openMomentoCache :
    Component a
    -> String
    -> Procedure.Procedure String SessionKey Msg
openMomentoCache component channelName =
    let
        _ =
            Debug.log "procedure" "momentoApi.open"
    in
    momentoApi.open
        { apiKey = component.momentoApiKey
        , cache = cacheName channelName
        }
        |> Procedure.fetchResult
        |> Procedure.mapError (always "Momento error")


recordChannelToDB : SessionKey -> Procedure.Procedure String SessionKey Msg
recordChannelToDB sessionKey =
    let
        _ =
            Debug.log "procedure" "dynamoApi.put"
    in
    dynamoApi.put
        { tableName = "someTable"
        , item = Encode.object [ ( "test", Encode.string "val" ) ]
        }
        |> Procedure.fetchResult
        |> Procedure.map (always sessionKey)
        |> Procedure.mapError (always "Dynamo error")


setupChannelWebhook :
    Component a
    -> String
    -> SessionKey
    -> Procedure.Procedure String () Msg
setupChannelWebhook component channelName sessionKey =
    let
        _ =
            Debug.log "procedure" "momentoApi.processOps"
    in
    momentoApi.processOps
        sessionKey
        [ Momento.webhookOp
            { topic = notifyTopicName channelName
            , url = component.channelApiUrl ++ "/v1/channel/" ++ channelName
            }
        ]
        |> Procedure.fetchResult
        |> Procedure.map (always ())
        |> Procedure.mapError (always "Momento error")


nameGenerator : Random.Generator String
nameGenerator =
    Random.String.string 10 Random.Char.english



-- Save Channel Events


{-| Channel save:

    * Obtain a connection to the cache.
    * Read the saved events from the cache list.
    * Save the events to the dynamodb event log.
    * Remove the saved events from the cache list.
    * Publish the saved event to the model topic.

-}
saveChannelEvent =
    ()



-- Internal Side Effects


dynamoPorts : Dynamo.Ports msg
dynamoPorts =
    { get = Ports.dynamoGet
    , put = Ports.dynamoPut
    , delete = Ports.dynamoDelete
    , batchGet = Ports.dynamoBatchGet
    , batchWrite = Ports.dynamoBatchWrite
    , query = Ports.dynamoQuery
    , response = Ports.dynamoResponse
    }


dynamoApi : Dynamo.DynamoApi Msg
dynamoApi =
    Dynamo.dynamoApi ProcedureMsg dynamoPorts


momentoPorts : Momento.Ports msg
momentoPorts =
    { open = Ports.mmOpen
    , close = Ports.mmClose
    , subscribe = Ports.mmSubscribe
    , publish = Ports.mmPublish
    , onMessage = Ports.mmOnMessage
    , pushList = Ports.mmPushList
    , createWebhook = Ports.mmCreateWebhook
    , response = Ports.mmResponse
    , asyncError = Ports.mmAsyncError
    }


momentoApi : Momento.MomentoApi Msg
momentoApi =
    Momento.momentoApi ProcedureMsg momentoPorts


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | RandomSeed Random.Seed
    | CreateChannelResponse (Result String ())


type Model
    = ModelStart StartState
    | ModelReady ReadyState


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


type alias StartState =
    {}


type alias ReadyState =
    { seed : Random.Seed
    , procedure : Procedure.Program.Model Msg
    }


subscriptions : Protocol (Component a) msg model -> Component a -> Sub msg
subscriptions protocol component =
    let
        model =
            component.eventLog
    in
    case model |> Debug.log "EventLog.subscriptions" of
        ModelReady state ->
            Procedure.Program.subscriptions state.procedure
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
        ( ModelReady state, ProcedureMsg innerMsg ) ->
            let
                ( procMdl, procMsg ) =
                    Procedure.Program.update
                        innerMsg
                        state.procedure
            in
            ( { state | procedure = procMdl }, procMsg )
                |> U2.andMap (switchState ModelReady)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelStart _, RandomSeed seed ) ->
            { seed = seed
            , procedure = Procedure.Program.init
            }
                |> U2.pure
                |> U2.andMap (switchState ModelReady)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( _, CreateChannelResponse res ) ->
            let
                _ =
                    Debug.log "=== CreateChannelResponse" res
            in
            U2.pure component
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate


randomize : StartState -> ( StartState, Cmd Msg )
randomize model =
    ( model
    , Random.generate RandomSeed Random.independentSeed
    )



--


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
