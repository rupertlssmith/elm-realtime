module AITrace.Component exposing (Component, Model, Msg, init, style, update, view)

import AITrace.Style
import AITrace.Trace.Prompt as Prompt
import AITrace.Trace.Response as Response
import AITrace.Trace.Spec exposing (Msg, Trace(..))
import AITrace.Trace.Trace as Trace
import Css.Global
import Html.Styled exposing (Html)


type alias Model =
    AITrace.Trace.Spec.Trace


type alias Msg =
    AITrace.Trace.Spec.Msg


style : List Css.Global.Snippet
style =
    AITrace.Style.style


type alias Component a =
    { a | trace : AITrace.Trace.Spec.Trace }


init : (Msg -> msg) -> ( Component {}, Cmd msg )
init toMsg =
    Trace.init
        |> Tuple.mapFirst (Trace.add Prompt.prompt)
        |> Tuple.mapFirst (Trace.add Response.response)
        |> Tuple.mapFirst (\x -> { trace = x })
        |> Tuple.mapSecond (Cmd.map toMsg)


update : (Msg -> msg) -> Msg -> Component a -> ( Component a, Cmd msg )
update toMsg msg model =
    Trace.update msg model.trace
        |> Tuple.mapFirst (\x -> { model | trace = x })
        |> Tuple.mapSecond (Cmd.map toMsg)


view : (Msg -> msg) -> Component a -> Html msg
view toMsg model =
    Trace.view toMsg model.trace
