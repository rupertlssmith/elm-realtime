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
import Json.Encode as Encode exposing (Value)
import Procedure.Program
import Realtime exposing (Error)
import Update2 as U2


type alias Component a =
    { a | app : Model }


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | JoinedChannel (Result Error Realtime.Model)
    | MMOnMessage Value


type alias Model =
    { procedure : Procedure.Program.Model Msg
    , realtime : Realtime.Model
    , log : List String
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
    , realtimeApi.onMessage model.realtime MMOnMessage
    ]
        |> Sub.batch
        |> Sub.map protocol.toMsg


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.app
    in
    case msg |> Debug.log "update" of
        ProcedureMsg innerMsg ->
            let
                ( procMdl, procMsg ) =
                    Procedure.Program.update innerMsg model.procedure
            in
            ( { model | procedure = procMdl }, procMsg )
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        MMOnMessage payload ->
            { model | log = ("Message: " ++ String.slice 0 90 (Encode.encode 2 payload) ++ "...") :: model.log }
                |> U2.pure
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate


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
