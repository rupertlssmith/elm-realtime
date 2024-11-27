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
import Json.Encode as Encode
import Momento exposing (Error, MomentoSessionKey)
import Ports
import Procedure
import Procedure.Program
import Random
import Random.Char
import Random.String
import Server.API as Api exposing (ApiRequest, Error(..), HttpSessionKey)
import Serverless.Conn.Body as Body
import Serverless.Conn.Request as Request exposing (Method(..))
import Serverless.Conn.Response as Body
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


processRoute : Protocol (Component a) msg model -> HttpSessionKey -> ApiRequest Route -> Component a -> ( model, Cmd msg )
processRoute protocol session route component =
    let
        model =
            component.eventLog
    in
    case ( Request.method route.request, route.route, model ) |> Debug.log "processRoute" of
        ( GET, ChannelRoot, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (createChannel protocol session state)

        ( POST, ChannelRoot, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (createChannel protocol session state)

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
createChannel : Protocol (Component a) msg model -> HttpSessionKey -> ReadyState -> Component a -> ( model, Cmd msg )
createChannel protocol session state component =
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
                |> Procedure.andThen (createChannelResponse session "Created Channel Ok")
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
    -> Procedure.Procedure String MomentoSessionKey Msg
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


recordChannelToDB : MomentoSessionKey -> Procedure.Procedure String MomentoSessionKey Msg
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
    -> MomentoSessionKey
    -> Procedure.Procedure String () Msg
setupChannelWebhook component channelName sessionKey =
    let
        _ =
            Debug.log "procedure" "momentoApi.processOps"
    in
    momentoApi.webhook
        sessionKey
        { topic = notifyTopicName channelName
        , url = component.channelApiUrl ++ "/v1/channel/" ++ channelName
        }
        |> Procedure.fetchResult
        |> Procedure.map (always ())
        |> Procedure.mapError (always "Momento error")


createChannelResponse :
    HttpSessionKey
    -> String
    -> ()
    -> Procedure.Procedure String () Msg
createChannelResponse session message _ =
    let
        _ =
            Debug.log "procedure" "createChannelResponse"
    in
    httpServerApi.response session (Body.ok200 message)
        |> Procedure.do
        |> Procedure.mapError (always "HTTP error")


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


httpServerProtocol : Api.Protocol Msg Route
httpServerProtocol =
    { ports =
        { request = Ports.requestPort
        , response = Ports.responsePort
        }
    , parseRoute = routeParser
    }


httpServerApi : Api.HttpServerApi Msg Route
httpServerApi =
    Api.httpServerApi httpServerProtocol


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | RandomSeed Random.Seed
    | HttpRequest HttpSessionKey (Result Api.Error (ApiRequest Route))
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
            [ Procedure.Program.subscriptions state.procedure
            , httpServerApi.request HttpRequest
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

        ( ModelReady state, HttpRequest session result ) ->
            case result of
                Ok apiRequest ->
                    processRoute protocol session apiRequest component

                Err (Error errMsg) ->
                    ( ModelReady state
                    , Body.err500 errMsg
                        |> httpServerApi.response session
                    )
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
