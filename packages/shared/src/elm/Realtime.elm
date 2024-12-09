module Realtime exposing
    ( Config
    , Delta
    , Error
    , Model
    , RealtimeApi
    , errorToDetails
    , errorToString
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
    { join : Config -> (Result Error Model -> msg) -> Cmd msg
    , publishPersisted : Model -> Value -> (Result Error Delta -> msg) -> Cmd msg
    , publishTransient : Model -> Value -> (Result Error Delta -> msg) -> Cmd msg
    , onMessage : Model -> (Value -> msg) -> Sub msg
    , asyncError : Model -> (Error -> msg) -> Sub msg
    }


realtimeApi : (Procedure.Program.Msg msg -> msg) -> RealtimeApi msg
realtimeApi pt =
    { join = join pt
    , publishPersisted = publishPersisted pt
    , publishTransient = publishTransient pt
    , onMessage = onMessage pt
    , asyncError = asyncError pt
    }


type Model
    = Private
        { rtChannelApiUrl : String
        , momentoApiKey : String
        , state : State
        }


type alias Delta =
    Model -> Model


type State
    = StartState
    | RunningState RunningProps


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


errorToString : Error -> String
errorToString err =
    case err of
        HttpError _ ->
            ""

        MomentoError momentoErr ->
            Momento.errorToString momentoErr


errorToDetails : Error -> { message : String, details : Value }
errorToDetails err =
    case err of
        HttpError _ ->
            { message = "", details = Encode.null }

        MomentoError momentoErr ->
            Momento.errorToDetails momentoErr



-- Initialization procedure.


{-| Initializes the realtime channel:

    * Fetches the channel details from the Channel API.
    * Opens a connection to Momento.
    * Subscribes to the model topic for the channel.

-}
join :
    (Procedure.Program.Msg msg -> msg)
    ->
        { rtChannelApiUrl : String
        , momentoApiKey : String
        }
    -> (Result Error Model -> msg)
    -> Cmd msg
join pt props rt =
    let
        momentoApi =
            buildMomentoApi pt

        model =
            { rtChannelApiUrl = props.rtChannelApiUrl
            , momentoApiKey = props.momentoApiKey
            , state = StartState
            }
                |> Private

        initProcedure =
            randomize
                |> Procedure.andThen (getChannelDetails model)
                |> Procedure.andThen (openMomentoCache model momentoApi)
                |> Procedure.andThen (subscribeModelTopic momentoApi)
                |> Procedure.map
                    (\state ->
                        { rtChannelApiUrl = props.rtChannelApiUrl
                        , momentoApiKey = props.momentoApiKey
                        , state = RunningState state
                        }
                            |> Private
                    )
    in
    initProcedure
        |> Procedure.try pt rt


randomize : Procedure e Random.Seed msg
randomize =
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
    -> Procedure.Procedure Error RunningProps msg
openMomentoCache (Private model) momentoApi state =
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
    -> RunningProps
    -> Procedure.Procedure Error RunningProps msg
subscribeModelTopic momentoApi state =
    momentoApi.subscribe
        state.sessionKey
        { topic = state.channel.modelTopic }
        |> Procedure.fetchResult
        |> Procedure.mapError MomentoError
        |> Procedure.map
            (\sessionKey -> { state | sessionKey = sessionKey })



-- Send realtime messages on the channel.


{-| Sends a persisted message. This message will be assigned a unique and contiguous sequence number and
saved into an event log, before being forwarded to all clients on the same channel.
-}
publishPersisted :
    (Procedure.Program.Msg msg -> msg)
    -> Model
    -> Value
    -> (Result Error Delta -> msg)
    -> Cmd msg
publishPersisted pt (Private model) payload rt =
    let
        momentoApi =
            buildMomentoApi pt
    in
    case model.state of
        RunningState state ->
            let
                notice =
                    [ ( "rt", Encode.string "N" )
                    , ( "client", Encode.string "abcdef" )
                    ]
                        |> Encode.object

                unsaved =
                    [ ( "rt", Encode.string "U" )
                    , ( "client", Encode.string "abcdef" )
                    , ( "payload", payload )
                    ]
                        |> Encode.object
            in
            momentoApi.publish state.sessionKey { topic = state.channel.saveTopic, payload = notice }
                |> Procedure.fetchResult
                |> Procedure.andThen
                    (\sk ->
                        momentoApi.pushList sk
                            { list = state.channel.saveList, payload = unsaved }
                            |> Procedure.fetchResult
                    )
                |> Procedure.map
                    (\sk (Private innerModel) ->
                        case innerModel.state of
                            RunningState innerState ->
                                { innerModel | state = { innerState | sessionKey = sk } |> RunningState }
                                    |> Private

                            _ ->
                                innerModel |> Private
                    )
                |> Procedure.mapError MomentoError
                |> Procedure.try pt rt

        _ ->
            Cmd.none


{-| Sends a transient message. This message will be forwarded to all clients on the same channel, but will
not be saved.
-}
publishTransient :
    (Procedure.Program.Msg msg -> msg)
    -> Model
    -> Value
    -> (Result Error Delta -> msg)
    -> Cmd msg
publishTransient pt (Private model) payload rt =
    let
        momentoApi =
            buildMomentoApi pt
    in
    case model.state of
        RunningState state ->
            let
                transient =
                    [ ( "rt", Encode.string "T" )
                    , ( "client", Encode.string "abcdef" )
                    , ( "payload", payload )
                    ]
                        |> Encode.object
            in
            momentoApi.publish state.sessionKey { topic = state.channel.saveTopic, payload = transient }
                |> Procedure.fetchResult
                |> Procedure.map
                    (\sk (Private innerModel) ->
                        case innerModel.state of
                            RunningState innerState ->
                                { innerModel | state = { innerState | sessionKey = sk } |> RunningState }
                                    |> Private

                            _ ->
                                innerModel |> Private
                    )
                |> Procedure.mapError MomentoError
                |> Procedure.try pt rt

        _ ->
            Cmd.none



-- Receive messages from the channel.


onMessage :
    (Procedure.Program.Msg msg -> msg)
    -> Model
    -> (Value -> msg)
    -> Sub msg
onMessage pt (Private model) rt =
    let
        momentoApi =
            buildMomentoApi pt
    in
    case model.state of
        RunningState state ->
            (\val -> momentoApi.onMessage (always val))
                rt

        _ ->
            Sub.none


asyncError :
    (Procedure.Program.Msg msg -> msg)
    -> Model
    -> (Error -> msg)
    -> Sub msg
asyncError pt (Private model) rt =
    let
        momentoApi =
            buildMomentoApi pt
    in
    case model.state of
        RunningState state ->
            momentoApi.asyncError (\err -> MomentoError err |> rt)

        _ ->
            Sub.none


cacheName : String -> String
cacheName _ =
    "elm-realtime-cache"
