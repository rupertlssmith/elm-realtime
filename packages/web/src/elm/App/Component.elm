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
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Procedure.Program
import Realtime exposing (AsyncEvent(..), Delta, Error, RTMessage(..), Snapshot)
import Update2 as U2


type alias Component a =
    { a | app : Model }


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | JoinedChannel (Delta (Result Error (List RTMessage)))
    | PublishAck (Delta (Maybe Error))
    | OnAsyncEvent (Delta AsyncEvent)


type alias Model =
    { procedure : Procedure.Program.Model Msg
    , realtime : Realtime.Model
    , log : List String
    , sharedModel : SharedModel
    }


setModel m x =
    { m | app = x }


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


realtimeApi : Realtime.RealtimeApi Msg
realtimeApi =
    Realtime.realtimeApi ProcedureMsg


init :
    { rtChannelApiUrl : String
    , momentoApiKey : String
    }
    -> (Msg -> msg)
    -> ( Model, Cmd msg )
init flags toMsg =
    let
        realtime =
            realtimeApi.init flags
    in
    ( { procedure = Procedure.Program.init
      , realtime = realtime
      , log = [ "Started" ]
      , sharedModel = initSharedModel
      }
    , realtimeApi.join realtime JoinedChannel
    )
        |> Tuple.mapSecond (Cmd.map toMsg)


subscriptions : Protocol (Component a) msg model -> Component a -> Sub msg
subscriptions protocol component =
    let
        model =
            component.app
    in
    [ Procedure.Program.subscriptions model.procedure
    , realtimeApi.subscribe model.realtime OnAsyncEvent
    ]
        |> Sub.batch
        |> Sub.map protocol.toMsg


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.app
    in
    case msg |> Debug.log "App.update" of
        ProcedureMsg innerMsg ->
            let
                ( procMdl, procMsg ) =
                    Procedure.Program.update innerMsg model.procedure
            in
            ( { model | procedure = procMdl }, procMsg )
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        JoinedChannel delta ->
            case Realtime.next delta model.realtime of
                ( nextRealtime, Ok events ) ->
                    let
                        hello =
                            [ ( "message", Encode.string "hello" ) ] |> Encode.object

                        sharedModel =
                            compact events initSharedModel
                    in
                    ( { model
                        | realtime = nextRealtime
                        , log = printSharedModel sharedModel :: model.log
                        , sharedModel = sharedModel
                      }
                    , Cmd.batch
                        [ realtimeApi.publishTransient nextRealtime hello PublishAck
                        , realtimeApi.publishPersisted nextRealtime hello PublishAck
                        ]
                    )
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate

                ( nextRealtime, Err err ) ->
                    { model
                        | realtime = nextRealtime
                        , log = ("Error: " ++ Realtime.errorToString err) :: model.log
                    }
                        |> U2.pure
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate

        PublishAck delta ->
            case Realtime.next delta model.realtime of
                ( nextRealtime, _ ) ->
                    { model | realtime = nextRealtime }
                        |> U2.pure
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate

        OnAsyncEvent delta ->
            case Realtime.next delta model.realtime of
                ( nextRealtime, Internal ) ->
                    { model | realtime = nextRealtime }
                        |> U2.pure
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate

                ( nextRealtime, OnMessage (Transient payload) ) ->
                    let
                        nextSharedModel =
                            compact [ Transient payload ] model.sharedModel
                    in
                    { model
                        | realtime = nextRealtime
                        , log =
                            printSharedModel nextSharedModel
                                :: printTransientEvent payload
                                :: model.log
                        , sharedModel = nextSharedModel
                    }
                        |> U2.pure
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate

                ( nextRealtime, OnMessage (Persisted seq payload) ) ->
                    let
                        nextSharedModel =
                            compact [ Persisted seq payload ] model.sharedModel
                    in
                    { model
                        | realtime = nextRealtime
                        , log =
                            printSharedModel nextSharedModel
                                :: printPersistedEvent seq payload
                                :: model.log
                        , sharedModel = nextSharedModel
                    }
                        |> U2.pure
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate

                ( nextRealtime, AsyncError err ) ->
                    { model
                        | realtime = nextRealtime
                        , log = ("Error: " ++ Realtime.errorToString err) :: model.log
                    }
                        |> U2.pure
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.onUpdate


type alias SharedModel =
    Snapshot { message : String }


initSharedModel =
    { seq = 0, model = { message = "start" } }


compact : List RTMessage -> SharedModel -> SharedModel
compact events sm =
    let
        messageDecoder =
            Decode.field "message" Decode.string

        apply payload m =
            case Decode.decodeValue messageDecoder payload of
                Ok message ->
                    { m | model = { message = message } }

                Err err ->
                    m

        doOne evt m =
            case evt of
                Transient payload ->
                    apply payload m

                Persisted seq payload ->
                    apply payload { m | seq = seq }
    in
    List.foldl
        doOne
        sm
        events


printSharedModel : SharedModel -> String
printSharedModel sm =
    "SharedModel: "
        ++ String.fromInt sm.seq
        ++ " "
        ++ sm.model.message


printTransientEvent : Value -> String
printTransientEvent payload =
    let
        stringPayload =
            Encode.encode 2 payload
    in
    "Transient: "
        ++ String.slice 0 200 stringPayload
        ++ (if String.length stringPayload > 200 then
                "..."

            else
                ""
           )


printPersistedEvent : Int -> Value -> String
printPersistedEvent seq payload =
    let
        stringPayload =
            Encode.encode 2 payload
    in
    "Persisted: "
        ++ String.fromInt seq
        ++ " "
        ++ String.slice 0 200 stringPayload
        ++ (if String.length stringPayload > 200 then
                "..."

            else
                ""
           )


view : Component a -> Html msg
view component =
    logs component.app


logs : { a | log : List String } -> Html msg
logs model =
    List.foldl
        (\entry acc -> Html.text (entry ++ "\n") :: acc)
        []
        model.log
        |> Html.pre []
