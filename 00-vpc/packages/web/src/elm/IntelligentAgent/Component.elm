module IntelligentAgent.Component exposing
    ( Model
    , Msg
    , Protocol
    , addAIStep
    , conversationReady
    , init
    , style
    , subscriptions
    , update
    , view
    )

import Browser.Dom
import BrowserInfo exposing (BrowserInfo(..))
import ChatBox.Editor as Editor exposing (Selection(..))
import Css.Global
import Domain.Conversation exposing (Conversation, Step)
import Html.Styled as HS
import Html.Styled.Attributes as HA
import IntelligentAgent.DecisionTree as DecisionTree
import IntelligentAgent.Model exposing (Animation(..), GestureCondition(..), Model, ViewMode(..))
import IntelligentAgent.Msg as Msg exposing (GestureLocation(..), Msg(..))
import IntelligentAgent.Style
import IntelligentAgent.Update as Update exposing (Protocol)
import IntelligentAgent.View as View exposing (Actions)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Pixels
import Point2d
import Pointer
import Ports
import Resize
import Task
import Task.Extra
import Update2 as U2


type alias Model =
    IntelligentAgent.Model.Model


type alias Msg =
    Msg.Msg


type alias Protocol submodel msg model =
    Update.Protocol submodel msg model


style : List Css.Global.Snippet
style =
    IntelligentAgent.Style.style


type alias Reset =
    { intelligentAgent : IntelligentAgent.Model.Model }


type alias Component a =
    { a
        | intelligentAgent : IntelligentAgent.Model.Model
        , chatApiUrl : String
        , conversation : Conversation
    }


init : (Msg -> msg) -> ( Reset, Cmd msg )
init toMsg =
    let
        pointerConfig =
            { dragThreshold = 3
            , holdTimeMillis = 1000
            , mouseWheelZoomStep = 1.1
            }
                |> Just

        docPointerHandlers =
            { dragStart = Msg.OnDragStart
            , drag = Msg.OnDrag
            , dragEnd = Msg.OnDragEnd
            }

        docPointerHandler =
            Pointer.empty
                |> Pointer.onDragStart 0 docPointerHandlers
                |> Pointer.onDrag 0 docPointerHandlers

        docPointer =
            Pointer.init
                pointerConfig
                (Msg.OnPointerMsg Doc)
                |> Pointer.apply docPointerHandler

        divPointerHandlers =
            { dragStart = Msg.OnDragDropStart
            }

        divPointerHandler =
            Pointer.empty
                |> Pointer.onDragStart 0 divPointerHandlers

        divPointer =
            Pointer.init
                pointerConfig
                (Msg.OnPointerMsg Div)
                |> Pointer.apply divPointerHandler

        editorConfig =
            { editorId = "chatbox"
            , editorClass = "ia-chat-user-input"
            , textMarkdown = ""
            , viewStyles = { fontSize = 16 }
            , resizeDecoder = Resize.resizeDecoder
            , browserInfo = Unknown
            }
    in
    ( { intelligentAgent =
            { chatSteps = []
            , pending = []
            , show = False
            , gesturesOnDoc = docPointer
            , gesturesOnDiv = divPointer
            , animation = Stopped
            , viewMode = ViewAll
            , lastPosition = 0
            , decisionTree = Just DecisionTree.example
            , pos = Point2d.xy (Pixels.float 120) (Pixels.float 150)
            , gestureCondition = NoGesture
            , prompt = ""
            , chatbox = Editor.init editorConfig Editor.NoSelection
            }
      }
    , Cmd.batch
        [ TryOpen { elementId = "intro" } |> Task.Extra.message
        , Browser.Dom.focus editorConfig.editorId |> Task.attempt (always Noop)
        ]
        |> Cmd.map toMsg
    )


subscriptions : Component a -> Sub Msg
subscriptions model =
    Sub.batch
        [ Pointer.subscriptions
            { onPointerDown = Ports.onPointerDown
            , onPointerUp = Ports.onPointerUp
            , onPointerMove = Ports.onPointerMove
            , onPointerCancel = Ports.onPointerCancel
            }
            model.intelligentAgent.gesturesOnDoc
            (\_ -> rootDecoder "ia-chat-topbar")
        , Update.subscriptions model.intelligentAgent
        ]


rootDecoder : String -> Decoder Value
rootDecoder rootId =
    Decode.at [ "target", "id" ] Decode.string
        |> Decode.map Encode.string


mapProtocol : Component a -> Protocol (Component a) msg model -> Protocol Model msg model
mapProtocol model protocol =
    let
        setIntelligentAgent agent =
            { model | intelligentAgent = agent }
    in
    { toMsg = protocol.toMsg
    , chatApiUrl = protocol.chatApiUrl
    , onUpdate = Tuple.mapFirst setIntelligentAgent >> protocol.onUpdate
    , onUserPrompt = \prompt -> Tuple.mapFirst setIntelligentAgent >> protocol.onUserPrompt prompt
    }


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg model =
    Update.update (mapProtocol model protocol) msg model.intelligentAgent


conversationReady : Protocol (Component a) msg model -> String -> Component a -> ( model, Cmd msg )
conversationReady protocol convId model =
    Debug.todo "conversationReady"


addAIStep : Protocol (Component a) msg model -> Step -> Component a -> ( model, Cmd msg )
addAIStep protocol step model =
    Update.addAIStep (mapProtocol model protocol) step model.intelligentAgent


view : Actions msg -> Component a -> HS.Html msg
view actions model =
    HS.div [ HA.class "intelligent-agent" ]
        [ View.view actions model.intelligentAgent
        ]
