module IntelligentAgent.Msg exposing (GestureLocation(..), Msg(..))

import ChatBox.Editor as Editor
import Domain.Conversation exposing (Step)
import Geometry exposing (Screen, VScene)
import Http
import Json.Encode exposing (Value)
import Pointer


type Msg
    = EditorMsg Editor.Msg
    | OnPointerMsg GestureLocation (Pointer.Msg Value Screen)
    | OnDragDropStart (Pointer.DragArgs Screen) Value
    | OnDragStart (Pointer.DragArgs Screen) Value
    | OnDrag (Pointer.DragArgs Screen) Value Value
    | OnDragEnd (Pointer.DragArgs Screen) Value Value
    | AnimDelta Float
    | NextItem String
    | TryOpen { elementId : String }
    | Toggle
    | Close
    | ShowAll
    | EnterPrompt String
    | Submit String
    | Noop


type GestureLocation
    = Doc
    | Div
