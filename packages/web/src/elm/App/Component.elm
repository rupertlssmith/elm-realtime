module App.Component exposing
    ( Model
    , Msg
    , Protocol
    , init
    , mmError
    , mmMessage
    , mmOpened
    , mmSubscribed
    , update
    , view
    )

import Html.Styled as Html exposing (Html)
import Http
import Json.Encode as Encode
import Momento exposing (Error, Op, OpenParams, SubscribeParams)
import Random
import Update2 as U2


type alias Component a =
    { a
        | location : String
        , momentoApiKey : String
        , app : Model
    }


setModel m x =
    { m | app = x }


type Msg
    = RandomSeed Random.Seed
    | LoggedIn (Result Http.Error ())


type Model
    = ModelStart StartState
    | ModelRandomized RandomizedState
    | ModelConnected ConnectedState
    | ModelRunning RunningState


type alias StartState =
    { log : List String
    , realtimeChannel : String
    }


type alias RandomizedState =
    { log : List String
    , realtimeChannel : String
    , seed : Random.Seed
    }


type alias ConnectedState =
    { log : List String
    , realtimeChannel : String
    , socketHandle : String
    , seed : Random.Seed
    }


type alias RunningState =
    { log : List String
    , realtimeChannel : String
    , socketHandle : String
    , seed : Random.Seed
    }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )

    -- Momento interface.
    , mmOpen : String -> OpenParams -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , mmSubscribe : String -> SubscribeParams -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , mmOps : String -> List Op -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : String -> (Msg -> msg) -> ( Model, Cmd msg )
init realtimeChannel toMsg =
    { log = [ "Started" ]
    , realtimeChannel = realtimeChannel
    }
        |> U2.pure
        |> U2.andMap randomize
        |> U2.andMap (switchState ModelStart)
        |> Tuple.mapSecond (Cmd.map toMsg)


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.app
    in
    case ( model, msg ) of
        ( ModelStart state, RandomSeed seed ) ->
            { log = "Randomized" :: state.log
            , realtimeChannel = state.realtimeChannel
            , seed = seed
            }
                |> U2.pure
                |> U2.andMap (switchState ModelRandomized)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.mmOpen "socket"
                    { apiKey = component.momentoApiKey
                    , cache = cacheName state.realtimeChannel
                    }

        _ ->
            U2.pure component
                |> protocol.onUpdate


randomize : StartState -> ( StartState, Cmd Msg )
randomize model =
    ( model
    , Random.generate RandomSeed Random.independentSeed
    )


mmOpened : Protocol (Component a) msg model -> String -> Component a -> ( model, Cmd msg )
mmOpened protocol id component =
    let
        model =
            component.app
    in
    case model of
        ModelRandomized state ->
            { log = "Connected" :: state.log
            , realtimeChannel = state.realtimeChannel
            , seed = state.seed
            , socketHandle = id
            }
                |> U2.pure
                |> U2.andMap (switchState ModelConnected)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.mmSubscribe id { topic = modelTopicName state.realtimeChannel }

        _ ->
            U2.pure component
                |> protocol.onUpdate


mmSubscribed : Protocol (Component a) msg model -> String -> SubscribeParams -> Component a -> ( model, Cmd msg )
mmSubscribed protocol id params component =
    let
        _ =
            Debug.log "Component.mmSubscribed" "called"

        model =
            component.app

        payload =
            [ ( "id", Encode.string "123456" )
            , ( "client", Encode.string "abcdef" )
            , ( "seq", Encode.int 1 )
            , ( "value", Encode.string "hello" )
            ]
                |> Encode.object
                |> Encode.encode 2

        notice =
            [ ( "client", Encode.string "abcdef" )
            , ( "seq", Encode.int 1 )
            , ( "kind", Encode.string "Listed" )
            ]
                |> Encode.object
                |> Encode.encode 2
    in
    case model of
        ModelConnected state ->
            { log =
                ("PushList: " ++ payload)
                    :: ("Publish: " ++ notice)
                    :: ("Subscribed: " ++ params.topic)
                    :: state.log
            , realtimeChannel = state.realtimeChannel
            , seed = state.seed
            , socketHandle = id
            }
                |> U2.pure
                |> U2.andMap (switchState ModelRunning)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.mmOps id
                    [ Momento.publish { topic = notifyTopicName state.realtimeChannel, payload = notice }
                    , Momento.pushList { list = saveListName state.realtimeChannel, payload = payload }
                    , Momento.publish { topic = modelTopicName state.realtimeChannel, payload = payload }
                    ]

        _ ->
            U2.pure component
                |> protocol.onUpdate


mmMessage : Protocol (Component a) msg model -> String -> String -> Component a -> ( model, Cmd msg )
mmMessage protocol id payload component =
    let
        model =
            component.app
    in
    case model of
        ModelRunning state ->
            { state | log = ("Message: " ++ String.slice 0 90 payload ++ "...") :: state.log }
                |> U2.pure
                |> U2.andMap (switchState ModelRunning)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate


mmError : Protocol (Component a) msg model -> String -> Error -> Component a -> ( model, Cmd msg )
mmError protocol id error component =
    component
        |> U2.pure
        |> protocol.onUpdate


view : Component a -> Html msg
view component =
    case component.app of
        ModelStart props ->
            logs props

        ModelRandomized props ->
            logs props

        ModelConnected props ->
            logs props

        ModelRunning props ->
            logs props


logs : { a | log : List String } -> Html msg
logs model =
    List.foldl
        (\entry acc -> Html.text (entry ++ "\n") :: acc)
        []
        model.log
        |> Html.pre []


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
