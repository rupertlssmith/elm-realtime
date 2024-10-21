module IntelligentAgent.Chat.Chat exposing (Model, add, empty, init, svgDrawing, update, view, viewScene)

import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
import IntelligentAgent.Chat.Spec as Spec exposing (Chat(..), ChatStep(..), ViewContextIF)
import IntelligentAgent.Msg exposing (Msg(..))
import Update2 as U2



-- The entire Chat as a TEA component.


init : ( Chat, Cmd Msg )
init =
    ( empty, Cmd.none )


update : Msg -> Chat -> ( Chat, Cmd Msg )
update _ trace =
    U2.pure trace


view : (Msg -> msg) -> Chat -> Html msg
view toMSg (Chat trace) =
    trace.view () |> HS.map toMSg



-- Chat functions.


add : ChatStep Msg -> Chat -> Chat
add entry (Chat trace) =
    trace.add entry



-- The Chat implementation.


type alias Model =
    { entities : List (ChatStep Msg)
    }


empty : Chat
empty =
    let
        addChatStep entry model =
            { model | entities = entry :: model.entities }
    in
    Spec.trace
        { view = viewScene
        , add = addChatStep
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
                        --                     [ H.text "AI Chat" ]
                        [ svgDrawing model ]
                    ]
                ]
            ]
        ]


svgDrawing : Model -> Html Msg
svgDrawing model =
    let
        context : ViewContextIF Msg
        context =
            { noop = Noop
            , toEditorMsg = EditorMsg
            }
    in
    List.foldl
        (\(ChatStep entry) accum -> entry.view context :: accum)
        []
        model.entities
        |> HS.div []
