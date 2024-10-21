module AITrace.Trace.Trace exposing (Model, add, init, update, view)

import AITrace.Trace.Spec as Spec exposing (LogEntry(..), Msg(..), Trace(..), ViewContextIF)
import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
import Update2 as U2



-- The entire Trace as a TEA component.


init : ( Trace, Cmd Msg )
init =
    ( empty, Cmd.none )


subscriptions : Trace -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Trace -> ( Trace, Cmd Msg )
update _ trace =
    U2.pure trace


view : (Msg -> msg) -> Trace -> Html msg
view toMSg (Trace trace) =
    trace.view () |> HS.map toMSg



-- Trace functions.


add : LogEntry Msg -> Trace -> Trace
add entry (Trace trace) =
    trace.add entry



-- The Trace implementation.


type alias Model =
    { entities : List (LogEntry Msg)
    }


empty : Trace
empty =
    let
        addLogEntry entry model =
            { model | entities = entry :: model.entities }
    in
    Spec.trace
        { view = viewScene
        , add = addLogEntry
        }
        { entities = []
        }



-- View


viewScene : Model -> Html Msg
viewScene model =
    HS.div [ HA.class "aitrace" ]
        [ HS.div [ HA.class "aitrace-frame" ]
            [ HS.div [ HA.class "aitrace-log-container" ]
                [ HS.div [ HA.class "aitrace-log" ]
                    [ HS.div [ HA.class "aitrace-text" ]
                        --                     [ H.text "AI Trace" ]
                        [ svgDrawing model ]
                    ]
                ]
            ]
        ]



-- H.div
-- [ HA.id "aitrace-container" ]
-- [ svgDrawing model ]


svgDrawing : Model -> Html Msg
svgDrawing model =
    let
        context : ViewContextIF Msg
        context =
            { noop = Noop
            }
    in
    List.foldl
        (\(LogEntry entry) accum -> entry.view context :: accum)
        []
        model.entities
        |> HS.div []
