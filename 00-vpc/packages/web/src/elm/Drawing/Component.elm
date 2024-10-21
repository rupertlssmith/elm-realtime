module Drawing.Component exposing
    ( Model
    , Msg
    , init
    , style
    , subscriptions
    , update
    , view
    )

import Browser.Dom exposing (Viewport)
import Browser.Events
import Css.Global
import Drawing.Model exposing (Model(..))
import Drawing.Msg exposing (Msg(..))
import Drawing.Scene.Drawing as Drawing
import Drawing.Scene.Root as Root
import Drawing.Scene.Spec exposing (Scene(..))
import Drawing.Style
import Geometry exposing (VScreen)
import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
import Html.Styled.Lazy as Lazy
import Task
import Update2 as U2
import Vector2d


type alias Model =
    Drawing.Model.Model


type alias Msg =
    Drawing.Msg.Msg


style : List Css.Global.Snippet
style =
    Drawing.Style.style


type alias Component a =
    { a | drawing : Drawing.Model.Model }


init : (Msg -> msg) -> ( Component {}, Cmd msg )
init toMsg =
    ( { drawing = SizingWindow }
    , Task.perform (viewportToSize >> WindowSize) Browser.Dom.getViewport
        |> Cmd.map toMsg
    )


subscriptions : Component a -> Sub Msg
subscriptions model =
    [ Browser.Events.onResize coordsToSize |> Sub.map WindowSize
    , case model.drawing of
        Ready (Scene scene) ->
            scene.subscriptions

        _ ->
            Sub.none
    ]
        |> Sub.batch



-- Window size conversions


coordsToSize : Int -> Int -> VScreen
coordsToSize x y =
    Vector2d.pixels (toFloat x) (toFloat y)


viewportToSize : Viewport -> VScreen
viewportToSize vport =
    Vector2d.pixels vport.viewport.width vport.viewport.height



-- Update


update : (Msg -> msg) -> Msg -> Component a -> ( Component a, Cmd msg )
update toMsg msg model =
    innerUpdate msg model.drawing
        |> Tuple.mapFirst (\x -> { model | drawing = x })
        |> Tuple.mapSecond (Cmd.map toMsg)


innerUpdate : Msg -> Model -> ( Model, Cmd Msg )
innerUpdate msg model =
    case ( model, msg ) of
        ( SizingWindow, WindowSize windowSize ) ->
            let
                drawing =
                    Drawing.empty windowSize "drawing-container"
                        |> Drawing.add "drawing-container" (Root.root "drawing-container")
            in
            U2.pure
                (Ready drawing)

        ( Ready (Scene scene), _ ) ->
            scene.update msg |> Tuple.mapFirst Ready

        _ ->
            U2.pure model



-- View


view : (Msg -> msg) -> Component a -> Html msg
view toMsg model =
    Lazy.lazy fullBody model.drawing |> HS.map toMsg


fullBody : Model -> Html Msg
fullBody model =
    case model of
        Ready (Scene scene) ->
            HS.div
                [ HA.id "top-container" ]
                [ scene.view () ]

        _ ->
            HS.div [] []
