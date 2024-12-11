module Realtime exposing
    ( AsyncEvent(..)
    , Config
    , Delta
    , Error
    , Model
    , RTMessage(..)
    , RealtimeApi
    , errorToDetails
    , errorToString
    , next
    , realtimeApi
    )

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Json.Encode as Encode exposing (Value)
import Momento exposing (Error, MomentoSessionKey, OpenParams, SubscribeParams)
import Ports
import Procedure exposing (Procedure)
import Procedure.Program
import Random


{-| Realtime channels.


# Set up and step the model.

@docs Config
@docs Model, Delta


# The Realtime API

@docs RealtimeApi, realtimeApi


# Error reporting

@docs Error, errorToDetails, errorToString

-}
type alias Config =
    { rtChannelApiUrl : String, momentoApiKey : String }


type alias RealtimeApi msg =
    { init : Config -> Model
    , join : Model -> (Result Error Model -> msg) -> Cmd msg
    , publishPersisted : Model -> Value -> (Delta (Maybe Error) -> msg) -> Cmd msg
    , publishTransient : Model -> Value -> (Delta (Maybe Error) -> msg) -> Cmd msg
    , subscribe : Model -> (Delta AsyncEvent -> msg) -> Sub msg
    }


realtimeApi : (Procedure.Program.Msg msg -> msg) -> RealtimeApi msg
realtimeApi pt =
    { init = init
    , join = join pt
    , publishPersisted = publishPersisted pt
    , publishTransient = publishTransient pt
    , subscribe = subscribe pt
    }


next : Delta a -> Model -> ( Model, a )
next (Delta delta) model =
    delta model


type RTMessage
    = Persisted Int Value
    | Transient Value


type Model
    = Private
        { rtChannelApiUrl : String
        , momentoApiKey : String
        , state : State
        , nonRunningEvents : List RTMessage
        }


type Delta a
    = Delta (Model -> ( Model, a ))


type State
    = StartState
    | JoiningState JoiningProps
    | RunningState RunningProps
    | FailedState Error


type alias JoiningProps =
    { sessionKey : MomentoSessionKey
    , seed : Random.Seed
    , channel : Channel
    , joinEvents : List RTMessage
    }


type alias RunningProps =
    { sessionKey : MomentoSessionKey
    , seed : Random.Seed
    , channel : Channel
    }


type alias Channel =
    { id : String
    , modelTopic : String
    , saveTopic : String
    , saveList : String
    , webhook : String
    }


channelDecoder : Decoder Channel
channelDecoder =
    Decode.succeed Channel
        |> DE.andMap (Decode.field "id" Decode.string)
        |> DE.andMap (Decode.field "modelTopic" Decode.string)
        |> DE.andMap (Decode.field "saveTopic" Decode.string)
        |> DE.andMap (Decode.field "saveList" Decode.string)
        |> DE.andMap (Decode.field "webhook" Decode.string)


buildMomentoApi : (Procedure.Program.Msg msg -> msg) -> Momento.MomentoApi msg
buildMomentoApi pt =
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
        |> Momento.momentoApi pt



-- Error reporting.


type Error
    = HttpError Http.Error
    | MomentoError Momento.Error
    | DecodeError Decode.Error


errorToString : Error -> String
errorToString err =
    case err of
        HttpError _ ->
            ""

        MomentoError momentoErr ->
            Momento.errorToString momentoErr

        DecodeError decodeErr ->
            Decode.errorToString decodeErr


errorToDetails : Error -> { message : String, details : Value }
errorToDetails err =
    case err of
        HttpError _ ->
            { message = "", details = Encode.null }

        MomentoError momentoErr ->
            Momento.errorToDetails momentoErr

        DecodeError decodeErr ->
            { message = Decode.errorToString decodeErr, details = Encode.null }



-- Initialization procedure.


{-| Initializeds the channel with its configuration.
-}
init : Config -> Model
init props =
    { rtChannelApiUrl = props.rtChannelApiUrl
    , momentoApiKey = props.momentoApiKey
    , state = StartState
    , nonRunningEvents = []
    }
        |> Private


{-| Joins the realtime channel in order to start an event flow:

    * Fetches the channel details from the Channel API.
    * Opens a connection to Momento.
    * Subscribes to the model topic for the channel.
    * Keeps any persisted events on the model topic in a temporary buffer.
    * Invokes the join API to request a snapshot + later persisted events.
    * Checks that the snapshot and later events are all contiguous.

-}
join :
    (Procedure.Program.Msg msg -> msg)
    -> Model
    -> (Result Error Model -> msg)
    -> Cmd msg
join pt (Private model) rt =
    let
        _ =
            Debug.log "Realtime.join" "called"

        momentoApi =
            buildMomentoApi pt

        initProcedure =
            randomize
                |> Procedure.andThen (getChannelDetails (Private model))
                |> Procedure.andThen (openMomentoCache (Private model) momentoApi)
                |> Procedure.andThen (subscribeModelTopic momentoApi)
                --|> Procedure.andThen (joinChannel (Private model))
                |> Procedure.map
                    (\state ->
                        { rtChannelApiUrl = model.rtChannelApiUrl
                        , momentoApiKey = model.momentoApiKey

                        --, state = JoiningState state
                        , state = RunningState state
                        , nonRunningEvents = model.nonRunningEvents
                        }
                            |> Private
                    )
    in
    initProcedure
        |> Procedure.try pt rt


randomize : Procedure e Random.Seed msg
randomize =
    let
        _ =
            Debug.log "Realtime.randomize" "called"
    in
    (\rt -> Random.generate rt Random.independentSeed)
        |> Procedure.fetch


getChannelDetails :
    Model
    -> Random.Seed
    ->
        Procedure Error
            { seed : Random.Seed
            , channel : Channel
            }
            msg
getChannelDetails (Private model) seed =
    let
        _ =
            Debug.log "Realtime.getChannelDetails" "called"
    in
    (\rt ->
        Http.get
            { url = model.rtChannelApiUrl ++ "/v1/channel"
            , expect = Http.expectJson rt channelDecoder
            }
    )
        |> Procedure.fetch
        |> Procedure.andThen
            (\getResult ->
                case getResult of
                    Ok channel ->
                        Procedure.provide channel

                    Err err ->
                        HttpError err |> Procedure.break
            )
        |> Procedure.map (\channel -> { seed = seed, channel = channel })


openMomentoCache :
    Model
    -> Momento.MomentoApi msg
    ->
        { seed : Random.Seed
        , channel : Channel
        }
    ->
        Procedure.Procedure Error
            { sessionKey : MomentoSessionKey
            , seed : Random.Seed
            , channel : Channel
            }
            msg
openMomentoCache (Private model) momentoApi state =
    let
        _ =
            Debug.log "Realtime.openMomentoCache" "called"
    in
    momentoApi.open
        { apiKey = model.momentoApiKey
        , cache = cacheName state.channel.id
        }
        |> Procedure.fetchResult
        |> Procedure.mapError MomentoError
        |> Procedure.map
            (\sessionKey ->
                { seed = state.seed
                , channel = state.channel
                , sessionKey = sessionKey
                }
            )


subscribeModelTopic :
    Momento.MomentoApi msg
    ->
        { sessionKey : MomentoSessionKey
        , seed : Random.Seed
        , channel : Channel
        }
    ->
        Procedure.Procedure Error
            { sessionKey : MomentoSessionKey
            , seed : Random.Seed
            , channel : Channel
            }
            msg
subscribeModelTopic momentoApi state =
    let
        _ =
            Debug.log "Realtime.subscribeModelTopic" "called"
    in
    momentoApi.subscribe
        state.sessionKey
        { topic = state.channel.modelTopic }
        |> Procedure.fetchResult
        |> Procedure.mapError MomentoError
        |> Procedure.map
            (\sessionKey -> { state | sessionKey = sessionKey })


joinChannel :
    Model
    ->
        { sessionKey : MomentoSessionKey
        , seed : Random.Seed
        , channel : Channel
        }
    ->
        Procedure Error
            { sessionKey : MomentoSessionKey
            , seed : Random.Seed
            , channel : Channel
            , joinEvents : List RTMessage
            }
            msg
joinChannel (Private model) state =
    let
        _ =
            Debug.log "Realtime.joinChannel" "called"
    in
    (\rt ->
        Http.get
            { url = model.rtChannelApiUrl ++ "/v1/channel/" ++ state.channel.id ++ "/join"
            , expect = Http.expectJson rt joinDecoder
            }
    )
        |> Procedure.fetch
        |> Procedure.andThen
            (\getResult ->
                case getResult of
                    Ok joinEvents ->
                        Procedure.provide joinEvents

                    Err err ->
                        HttpError err |> Procedure.break
            )
        |> Procedure.map
            (\joinEvents ->
                { seed = state.seed
                , channel = state.channel
                , sessionKey = state.sessionKey
                , joinEvents = joinEvents
                }
            )


joinDecoder : Decoder (List RTMessage)
joinDecoder =
    Decode.list rtMessageDecoder



-- Send realtime messages on the channel.


{-| Sends a persisted message. This message will be assigned a unique and contiguous sequence number and
saved into an event log, before being forwarded to all clients on the same channel.
-}
publishPersisted :
    (Procedure.Program.Msg msg -> msg)
    -> Model
    -> Value
    -> (Delta (Maybe Error) -> msg)
    -> Cmd msg
publishPersisted pt (Private model) payload tag =
    let
        _ =
            Debug.log "Realtime.publishPersisted" "called"

        momentoApi =
            buildMomentoApi pt
    in
    case model.state of
        RunningState state ->
            momentoApi.pushList state.sessionKey
                { list = state.channel.saveList, payload = encodeUnsaved payload }
                |> Procedure.fetchResult
                |> Procedure.andThen
                    (\nextSessionKey ->
                        momentoApi.publish nextSessionKey
                            { topic = state.channel.saveTopic
                            , payload = encodeNotice
                            }
                            |> Procedure.fetchResult
                    )
                |> Procedure.mapError MomentoError
                |> Procedure.try pt (momentoResultToDelta state tag)

        _ ->
            Cmd.none


momentoResultToDelta : RunningProps -> (Delta (Maybe Error) -> msg) -> Result Error MomentoSessionKey -> msg
momentoResultToDelta state tag res =
    case res of
        Ok nextSessionKey ->
            (\(Private m) ->
                ( { m
                    | state =
                        { state | sessionKey = nextSessionKey }
                            |> RunningState
                  }
                    |> Private
                , Nothing
                )
            )
                |> Delta
                |> tag

        Err err ->
            (\(Private m) ->
                ( { m | state = err |> FailedState } |> Private
                , err |> Just
                )
            )
                |> Delta
                |> tag


{-| Sends a transient message. This message will be forwarded to all clients on the same channel, but will
not be saved.
-}
publishTransient :
    (Procedure.Program.Msg msg -> msg)
    -> Model
    -> Value
    -> (Delta (Maybe Error) -> msg)
    -> Cmd msg
publishTransient pt (Private model) payload tag =
    let
        _ =
            Debug.log "Realtime.publishTransient" "called"

        momentoApi =
            buildMomentoApi pt
    in
    case model.state of
        RunningState state ->
            momentoApi.publish state.sessionKey
                { topic = state.channel.modelTopic
                , payload = encodeTransient payload
                }
                |> Procedure.fetchResult
                |> Procedure.mapError MomentoError
                |> Procedure.try pt (momentoResultToDelta state tag)

        _ ->
            Cmd.none



-- Receive messages from the channel.


type AsyncEvent
    = OnMessage RTMessage
    | AsyncError Error
    | Internal


subscribe :
    (Procedure.Program.Msg msg -> msg)
    -> Model
    -> (Delta AsyncEvent -> msg)
    -> Sub msg
subscribe pt (Private model) tag =
    let
        momentoApi =
            buildMomentoApi pt

        modfn val =
            case Decode.decodeValue rtMessageDecoder val of
                Ok rtm ->
                    (\m -> ( m, OnMessage rtm )) |> Delta |> tag

                Err err ->
                    (\(Private m) ->
                        ( { m | state = DecodeError err |> FailedState } |> Private
                        , DecodeError err |> AsyncError
                        )
                    )
                        |> Delta
                        |> tag

        errfn err =
            (\(Private m) ->
                ( { m | state = MomentoError err |> FailedState } |> Private
                , MomentoError err |> AsyncError
                )
            )
                |> Delta
                |> tag
    in
    case model.state of
        RunningState _ ->
            [ (\fn -> momentoApi.onMessage (\_ -> fn))
                modfn
            , momentoApi.asyncError
                errfn
            ]
                |> Sub.batch

        _ ->
            Sub.none


cacheName : String -> String
cacheName _ =
    "elm-realtime-cache"


rtMessageDecoder : Decoder RTMessage
rtMessageDecoder =
    Decode.field "rt" Decode.string
        |> Decode.andThen
            (\ctor ->
                case ctor of
                    "P" ->
                        Decode.map2 Persisted
                            (Decode.field "seq" Decode.int)
                            (Decode.field "payload" Decode.value)

                    "T" ->
                        Decode.map Transient
                            (Decode.field "payload" Decode.value)

                    _ ->
                        Decode.fail "Unrecognized constructor"
            )


encodeTransient : Value -> Value
encodeTransient payload =
    [ ( "rt", Encode.string "T" )
    , ( "client", Encode.string "abcdef" )
    , ( "payload", payload )
    ]
        |> Encode.object


encodeNotice : Value
encodeNotice =
    [ ( "rt", Encode.string "N" )
    , ( "client", Encode.string "abcdef" )
    ]
        |> Encode.object


encodeUnsaved : Value -> Value
encodeUnsaved payload =
    [ ( "rt", Encode.string "U" )
    , ( "client", Encode.string "abcdef" )
    , ( "payload", payload )
    ]
        |> Encode.object
