module EventLog.Component exposing (Component, Model(..), Msg(..), Protocol, RandomizedState, Route(..), StartState, cacheName, createChannel, init, mmError, mmOpened, modelTopicName, nameGenerator, notifyTopicName, processRoute, randomize, routeParser, saveChannelEvent, saveListName, setModel, switchState, update)

{-| API for managing realtime channels.
-}

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
    = V1ChannelRoot
    | V1Channel String


routeParser : Url -> Maybe Route
routeParser =
    UP.oneOf
        [ UP.map V1ChannelRoot (UP.s "v1" </> UP.s "channel")
        , UP.map V1Channel (UP.s "v1" </> UP.s "channel" </> UP.string)
        ]
        |> UP.map (Debug.log "route")
        |> UP.parse


processRoute : Protocol (Component a) msg model -> ApiRoute Route -> Component a -> ( model, Cmd msg )
processRoute protocol route component =
    case ( Request.method route.request, route.route ) |> Debug.log "processRoute" of
        ( GET, V1ChannelRoot ) ->
            U2.pure component
                |> U2.andMap (createChannel protocol)

        ( POST, V1ChannelRoot ) ->
            U2.pure component
                |> U2.andMap (createChannel protocol)

        ( POST, V1Channel _ ) ->
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



-- Channel Creation


{-| Channel creation:

    * Create the cache or confirm it already exists.
    * Create a dynamodb table for the persisted events or confirm it already exists.
    * Create a webhook on the save topic.
    * Return a confirmation that everything has been set up.

-}
createChannel : Protocol (Component a) msg model -> Component a -> ( model, Cmd msg )
createChannel protocol component =
    let
        model =
            component.eventLog
    in
    case model of
        ModelRandomized state ->
            let
                ( channelName, nextSeed ) =
                    Random.step nameGenerator state.seed

                _ =
                    Debug.log "createChannel" channelName
            in
            U2.pure { state | seed = nextSeed }
                |> U2.andMap (switchState ModelRandomized)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.mmOpen channelName
                    { apiKey = component.momentoApiKey
                    , cache = cacheName channelName
                    }

        _ ->
            U2.pure component
                |> protocol.onUpdate


{-| Invoked once the momento channel is confirmed open. Create a webhook on the save topic.
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
        ModelRandomized state ->
            U2.pure state
                |> U2.andMap (switchState ModelRandomized)
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
    | ModelRandomized RandomizedState


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


type alias StartState =
    {}


type alias RandomizedState =
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
                |> U2.andMap (switchState ModelRandomized)
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
