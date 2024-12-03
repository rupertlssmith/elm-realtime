module App.Component exposing
    ( Model
    , Msg
    , Protocol
    , init
    , subscriptions
    , update
    , view
    )

import Html.Styled as Html exposing (Html)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Json.Encode as Encode exposing (Value)
import Momento exposing (Error, MomentoSessionKey, OpenParams, SubscribeParams)
import Ports
import Procedure.Program
import Random
import Update2 as U2


type alias Component a =
    { a
        | chatApiUrl : String
        , momentoApiKey : String
        , app : Model
    }


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | RandomSeed Random.Seed
    | ChannelDetails (Result Http.Error Channel)
    | MMOpened (Result Error MomentoSessionKey)
    | MMSubscribed (Result Error MomentoSessionKey)
    | MMNotified (Result Error MomentoSessionKey)
    | MMOnMessage MomentoSessionKey Value


type alias Channel =
    { id : String
    , modelTopic : String
    , saveTopic : String
    , saveList : String
    , webhook : String
    }


type alias Model =
    { procedure : Procedure.Program.Model Msg
    , lifecycle : Lifecycle
    }


type Lifecycle
    = ModelStart StartState
    | ModelRandomized RandomizedState
    | ModelChannelDetails ChannelDetailsState
    | ModelConnected ConnectedState
    | ModelRunning RunningState


type alias StartState =
    { log : List String
    }


type alias RandomizedState =
    { log : List String
    , seed : Random.Seed
    }


type alias ChannelDetailsState =
    { log : List String
    , seed : Random.Seed
    , channel : Channel
    }


type alias ConnectedState =
    { log : List String
    , socketHandle : MomentoSessionKey
    , seed : Random.Seed
    , channel : Channel
    }


type alias RunningState =
    { log : List String
    , socketHandle : MomentoSessionKey
    , seed : Random.Seed
    , channel : Channel
    }


setModel m x =
    { m | app = x }


setLifecycle m x =
    { m | lifecycle = x }


switchState : (a -> Lifecycle) -> a -> ( Lifecycle, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


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


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    { log = [ "Started" ]
    }
        |> U2.pure
        |> U2.andMap randomize
        |> U2.andMap (switchState ModelStart)
        |> Tuple.mapFirst
            (\state ->
                { procedure = Procedure.Program.init
                , lifecycle = state
                }
            )
        |> Tuple.mapSecond (Cmd.map toMsg)


subscriptions : Protocol (Component a) msg model -> Component a -> Sub msg
subscriptions protocol component =
    let
        model =
            component.app
    in
    [ Procedure.Program.subscriptions model.procedure
    , momentoApi.onMessage MMOnMessage
    ]
        |> Sub.batch
        |> Sub.map protocol.toMsg


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.app

        lifecycle =
            model.lifecycle
    in
    case ( lifecycle, msg |> Debug.log "update" ) of
        ( _, ProcedureMsg innerMsg ) ->
            let
                ( procMdl, procMsg ) =
                    Procedure.Program.update innerMsg model.procedure
            in
            ( { model | procedure = procMdl }, procMsg )
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelStart state, RandomSeed seed ) ->
            { log = "Randomized" :: state.log
            , seed = seed
            }
                |> U2.pure
                |> U2.andThen (getChannelDetails component)
                |> U2.andMap (switchState ModelRandomized)
                |> Tuple.mapFirst (setLifecycle model)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelRandomized state, ChannelDetails (Ok channel) ) ->
            ( { log = "ChannelDetails" :: state.log
              , seed = state.seed
              , channel = channel
              }
            , momentoApi.open
                { apiKey = component.momentoApiKey
                , cache = cacheName
                }
                MMOpened
            )
                |> U2.andMap (switchState ModelChannelDetails)
                |> Tuple.mapFirst (setLifecycle model)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelChannelDetails state, MMOpened (Ok sessionKey) ) ->
            ( { log = "Connected" :: state.log
              , seed = state.seed
              , channel = state.channel
              , socketHandle = sessionKey
              }
            , momentoApi.subscribe
                sessionKey
                { topic = state.channel.modelTopic }
                MMSubscribed
            )
                |> U2.andMap (switchState ModelConnected)
                |> Tuple.mapFirst (setLifecycle model)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelConnected state, MMSubscribed (Ok sessionKey) ) ->
            let
                payload =
                    [ ( "id", Encode.string "123456" )
                    , ( "client", Encode.string "abcdef" )
                    , ( "seq", Encode.int 1 )
                    , ( "value", Encode.string "hello" )
                    ]
                        |> Encode.object

                notice =
                    [ ( "client", Encode.string "abcdef" )
                    , ( "seq", Encode.int 1 )
                    , ( "kind", Encode.string "Listed" )
                    ]
                        |> Encode.object
            in
            ( { log =
                    ("PushList: " ++ Encode.encode 2 payload)
                        :: ("Publish: " ++ Encode.encode 2 notice)
                        :: ("Subscribed: " ++ state.channel.modelTopic)
                        :: state.log
              , seed = state.seed
              , channel = state.channel
              , socketHandle = sessionKey
              }
            , Cmd.batch
                [ momentoApi.publish sessionKey
                    { topic = state.channel.saveTopic, payload = notice }
                , momentoApi.pushList sessionKey
                    { list = state.channel.saveList, payload = payload }
                    MMNotified

                --, momentoApi.publish sessionKey
                --    { topic = modelTopicName state.realtimeChannel, payload = payload }
                ]
            )
                |> U2.andMap (switchState ModelRunning)
                |> Tuple.mapFirst (setLifecycle model)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelRunning state, MMOnMessage _ payload ) ->
            { state | log = ("Message: " ++ String.slice 0 90 (Encode.encode 2 payload) ++ "...") :: state.log }
                |> U2.pure
                |> U2.andMap (switchState ModelRunning)
                |> Tuple.mapFirst (setLifecycle model)
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


channelDecoder : Decoder Channel
channelDecoder =
    Decode.succeed Channel
        |> DE.andMap (Decode.field "id" Decode.string)
        |> DE.andMap (Decode.field "modelTopic" Decode.string)
        |> DE.andMap (Decode.field "saveTopic" Decode.string)
        |> DE.andMap (Decode.field "saveList" Decode.string)
        |> DE.andMap (Decode.field "webhook" Decode.string)


getChannelDetails : Component a -> RandomizedState -> ( RandomizedState, Cmd Msg )
getChannelDetails component state =
    ( state
    , Http.get
        { url = component.chatApiUrl ++ "/v1/channel"
        , expect = Http.expectJson ChannelDetails channelDecoder
        }
    )


view : Component a -> Html msg
view component =
    case component.app.lifecycle of
        ModelStart props ->
            logs props

        ModelRandomized props ->
            logs props

        ModelChannelDetails props ->
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


cacheName : String
cacheName =
    "elm-realtime-cache"
