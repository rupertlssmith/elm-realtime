module IntelligentAgent.Model exposing
    ( Animation(..)
    , GestureCondition(..)
    , Model
    , Pending
    , ViewMode(..)
    )

import ChatBox.Editor as Editor
import Geometry exposing (PScreen, Screen)
import IntelligentAgent.ChatStep exposing (Item)
import IntelligentAgent.DecisionTree exposing (DecisionTree)
import IntelligentAgent.Msg exposing (Msg)
import Json.Encode exposing (Value)
import Pointer


type alias Model =
    { chatSteps : List ( String, Item, Bool )
    , pending : List Pending
    , show : Bool
    , gesturesOnDoc : Pointer.Model Value Msg Screen
    , gesturesOnDiv : Pointer.Model Value Msg Screen
    , animation : Animation
    , viewMode : ViewMode
    , lastPosition : Int
    , decisionTree : Maybe DecisionTree
    , pos : PScreen
    , gestureCondition : GestureCondition
    , prompt : String
    , chatbox : Editor.Model
    }


type GestureCondition
    = NoGesture
    | Dragging { prevPos : PScreen }


type ViewMode
    = ViewFrom Int
    | ViewAll


type alias Pending =
    { key : String
    , current : Item
    , remaining : Item
    , isNewTopic : Bool
    }


type Animation
    = Stopped
    | Running Float
