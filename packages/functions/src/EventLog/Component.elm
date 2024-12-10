module EventLog.Component exposing
    ( Component
    , Model
    , Msg
    , Protocol
    , init
    , subscriptions
    , update
    )

{-| API for managing realtime channels.
-}

import EventLog.Apis as Apis
import EventLog.CreateChannel as CreateChannel
import EventLog.GetAvailableChannel as GetAvailableChannel
import EventLog.JoinChannel as JoinChannel
import EventLog.Model as Model exposing (Model(..), ReadyState, StartState)
import EventLog.Msg as Msg exposing (Msg(..))
import EventLog.Route exposing (Route(..))
import EventLog.SaveChannel as SaveChannel
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Procedure.Program
import Random
import Result.Extra
import Serverless.HttpServer as HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Serverless.Request as Request exposing (Method(..))
import Serverless.Response as Response exposing (Response)
import Update2 as U2


type alias Model =
    Model.Model


type alias Msg =
    Msg.Msg


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


type alias Component a =
    { a
        | momentoApiKey : String
        , channelApiUrl : String
        , channelTable : String
        , eventLogTable : String
        , eventLog : Model
    }


setModel : Component a -> Model -> Component a
setModel m x =
    { m | eventLog = x }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


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
            , Apis.httpServerApi.request HttpRequest
            , Apis.momentoApi.asyncError MomentoError
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
                        |> Apis.httpServerApi.response session
                    )
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate

        ( _, HttpResponse session result ) ->
            ( component
            , result |> Result.Extra.merge |> Apis.httpServerApi.response session
            )
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( _, MomentoError error ) ->
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



-- API Routing


processRoute : Protocol (Component a) msg model -> HttpSessionKey -> ApiRequest Route -> Component a -> ( model, Cmd msg )
processRoute protocol session apiRequest component =
    let
        model =
            component.eventLog
    in
    case ( Request.method apiRequest.request, apiRequest.route, model ) of
        ( GET, ChannelRoot, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (GetAvailableChannel.getAvailableChannel session state)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( POST, ChannelRoot, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (CreateChannel.createChannel session state)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( POST, Channel channelName, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (SaveChannel.saveChannel session state apiRequest channelName)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( GET, ChannelJoin channelName, ModelReady state ) ->
            U2.pure component
                |> U2.andMap (JoinChannel.joinChannel session state apiRequest channelName)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate
