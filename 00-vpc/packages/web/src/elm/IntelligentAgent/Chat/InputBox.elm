module IntelligentAgent.Chat.InputBox exposing (Model, chatBox, encode, response, view)

import BrowserInfo exposing (BrowserInfo(..))
import ChatBox.Editor as Editor
import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
import Icon
import IntelligentAgent.Chat.Spec as Spec exposing (ChatStep, ViewContextIF)
import Json.Encode as Encode exposing (Value)
import Resize


type alias Model =
    { chatbox : Editor.Model
    }


response : ChatStep msg
response =
    let
        editorConfig =
            { editorId = "chatbox"
            , editorClass = "ia-chat-user-input"
            , textMarkdown = ""
            , viewStyles = { fontSize = 16 }
            , resizeDecoder = Resize.resizeDecoder
            , browserInfo = Unknown
            }
    in
    Spec.logEntry
        { view = view
        , encode = encode
        }
        { chatbox = Editor.init editorConfig Editor.NoSelection
        }


encode : Model -> Value
encode model =
    []
        |> Encode.object


view : ViewContextIF msg -> Model -> Html msg
view context model =
    chatBox context model


chatBox : ViewContextIF msg -> Model -> Html msg
chatBox context model =
    HS.div [ HA.class "ia-chat" ]
        [ HS.div
            [ HA.class "ia-chat-icon" ]
            [ Icon.robot |> HS.fromUnstyled ]
        , HS.div [ HA.class "ia-chat-text" ]
            [ HS.div [ HA.class "ia-chat-text-body" ]
                [ HS.div
                    [ HA.class "ia-chat-toolbar"
                    ]
                    [ Editor.view
                        { fontSize = 16
                        }
                        model.chatbox
                        |> HS.fromUnstyled
                        |> HS.map context.toEditorMsg
                    ]
                ]
            ]
        ]
