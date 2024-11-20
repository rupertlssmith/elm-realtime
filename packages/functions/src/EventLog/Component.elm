module EventLog.Component exposing (Component, Model(..), Msg(..), Protocol, ReadyState, Route(..), StartState, cacheName, createChannel, init, mmError, mmOpened, modelTopicName, nameGenerator, notifyTopicName, processRoute, randomize, routeParser, saveChannelEvent, saveListName, setModel, switchState, update)

{-| API for managing realtime channels.
-}

import AWS.Dynamo as Dynamo
import Dict exposing (Dict)
import Json.Encode as Encode
import Momento exposing (Error, Op(..), OpenParams)
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
    , mmOpen : String -> OpenParams -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , mmOps : String -> List Op -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
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
        ( channelName, nextSeed ) =
            Random.step nameGenerator state.seed

        _ =
            Debug.log "createChannel" channelName
    in
    U2.pure { seed = nextSeed }
        |> U2.andMap (ModelProcessing PostChannelRootStart |> switchState)
        |> Tuple.mapFirst (setModel component)
        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
        |> protocol.mmOpen channelName
            { apiKey = component.momentoApiKey
            , cache = cacheName channelName
            }


{-| Invoked when a momento channel is confirmed open.
-}
mmOpened : Protocol (Component a) msg model -> String -> Component a -> ( model, Cmd msg )
mmOpened protocol channelId component =
    let
        model =
            component.eventLog

        _ =
            Debug.log "mmOpened" ("channel " ++ channelId)
    in
    case model of
        ModelProcessing PostChannelRootStart state ->
            U2.pure state
                |> U2.andMap (ModelProcessing PostChannelRootChannelCreated |> switchState)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.mmOps channelId
                    [ Webhook
                        { topic = notifyTopicName channelId
                        , url = component.channelApiUrl ++ "/v1/channel/" ++ channelId
                        }
                    ]

        _ ->
            U2.pure component
                |> protocol.onUpdate


nameGenerator : Random.Generator String
nameGenerator =
    Random.String.string 10 Random.Char.english


mmError : Protocol (Component a) msg model -> String -> Error -> Component a -> ( model, Cmd msg )
mmError protocol id error component =
    let
        _ =
            Debug.log "mmError" ("channel " ++ id ++ " " ++ Debug.toString error)
    in
    component
        |> U2.pure
        |> protocol.onUpdate


dynamoResult : Protocol (Component a) msg model -> String -> Component a -> ( model, Cmd msg )
dynamoResult protocol id component =
    let
        model =
            component.eventLog

        _ =
            Debug.log "mmOpened" ("channel " ++ id)
    in
    case model of
        ModelProcessing PostChannelRootChannelCreated state ->
            U2.pure component
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate


mmOpsComplete : Protocol (Component a) msg model -> String -> Component a -> ( model, Cmd msg )
mmOpsComplete protocol id component =
    let
        model =
            component.eventLog

        _ =
            Debug.log "mmOpened" ("channel " ++ id)
    in
    case model of
        ModelProcessing PostChannelRootChannelCreated state ->
            U2.pure component
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate



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


type Msg
    = RandomSeed Random.Seed


type Model
    = ModelStart StartState
    | ModelReady ReadyState
    | ModelProcessing StateMachines ReadyState


type StateMachines
    = -- PostChannelRoute
      PostChannelRootStart
    | PostChannelRootChannelCreated
      -- Post Channel
    | PostChannel


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


type alias StartState =
    {}


type alias ReadyState =
    { seed : Random.Seed
    }


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.eventLog
    in
    case ( model, msg ) of
        ( ModelStart _, RandomSeed seed ) ->
            { seed = seed
            }
                |> U2.pure
                |> U2.andMap (switchState ModelReady)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
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
    channel ++ "-cache"


saveListName : String -> String
saveListName channel =
    channel ++ "-savelist"
