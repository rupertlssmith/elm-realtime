module Snapshot.Component exposing
    ( Component
    , Model
    , Msg
    , Protocol
    , init
    , subscriptions
    , update
    )

{-| API for managing realtime channel snapshots.
-}

import AWS.Credentials exposing (Credentials)
import Dict
import Http.Response as Response exposing (Response)
import HttpServer exposing (HttpSessionKey)
import Procedure.Program
import Random
import Result.Extra
import Snapshot.Apis as Apis
import Snapshot.Model as Model exposing (Model(..), ReadyState, StartState)
import Snapshot.Msg as Msg exposing (Msg(..))
import Snapshot.SnapshotChannel as SnapshotChannel
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
        | awsRegion : String
        , defaultCredentials : Credentials
        , momentoApiKey : String
        , channelApiUrl : String
        , channelTable : String
        , eventLogTable : String
        , snapshotQueueUrl : String
        , snapshot : Model
    }


setModel : Component a -> Model -> Component a
setModel m x =
    { m | snapshot = x }


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
            component.snapshot
    in
    case model of
        ModelReady state ->
            [ Procedure.Program.subscriptions state.procedure
            , Apis.sqsLambdaApi.event SqsEvent
            ]
                |> Sub.batch
                |> Sub.map protocol.toMsg

        _ ->
            Sub.none


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.snapshot
    in
    case ( model, msg ) of
        ( ModelStart _, RandomSeed seed ) ->
            { seed = seed
            , procedure = Procedure.Program.init
            , cache = Dict.empty
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

        ( ModelReady state, SqsEvent session event ) ->
            let
                _ =
                    Debug.log "Got SQS event" event
            in
            ( ModelReady state
            , "Ok"
                |> Response.ok200
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

        _ ->
            U2.pure component
                |> protocol.onUpdate


randomize : StartState -> ( StartState, Cmd Msg )
randomize model =
    ( model
    , Random.generate RandomSeed Random.independentSeed
    )
