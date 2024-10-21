module IntelligentAgent.Update exposing (Protocol, Update, addAIStep, subscriptions, update)

import Browser.Dom as Dom
import Browser.Events
import BrowserInfo exposing (BrowserInfo(..))
import ChatBox.Editor as Editor
import Dict
import Domain.Conversation exposing (Step(..))
import GapBuffer
import Geometry exposing (PScreen, Screen, VScene, VScreen)
import IntelligentAgent.ChatStep as ChatStep exposing (Item, ItemOrigin(..))
import IntelligentAgent.DecisionTree exposing (DecisionTree)
import IntelligentAgent.Model exposing (Animation(..), GestureCondition(..), ViewMode(..))
import IntelligentAgent.Msg exposing (GestureLocation(..), Msg(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode exposing (Value)
import Point2d
import Pointer
import Resize
import Task
import Task.Extra
import Update2 as U2
import Vector2d


subscriptions : Update a -> Sub Msg
subscriptions model =
    case model.animation of
        Stopped ->
            Sub.none

        Running _ ->
            Browser.Events.onAnimationFrameDelta AnimDelta


type alias Update a =
    { a
        | chatSteps : List ( String, Item, Bool )
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


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , chatApiUrl : String
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onUserPrompt : String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


editorProtocol : Update a -> Editor.Protocol Editor.Model Msg (Update a)
editorProtocol model =
    let
        setChatBox chatbox =
            { model
                | chatbox = chatbox
                , prompt = chatbox.textMarkdown
            }
    in
    { toMsg = EditorMsg
    , onUpdate = U2.map setChatBox
    , onResize = \id vec -> U2.map setChatBox >> U2.andThen (processResize id vec)
    , onSubmit = U2.map setChatBox >> U2.andThen processSubmit
    }


update : Protocol (Update a) msg model -> Msg -> Update a -> ( model, Cmd msg )
update protocol msg model =
    case msg of
        EditorMsg editorMsg ->
            Editor.update (editorProtocol model) editorMsg model.chatbox
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        AnimDelta animTime ->
            U2.pure model
                |> U2.andThen (processAnimation animTime)
                |> U2.andThen showScrolledToPosition
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        OnPointerMsg loc pointerMsg ->
            U2.pure model
                |> U2.andThen (processGesture loc pointerMsg)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        OnDragDropStart _ _ ->
            U2.pure model
                |> protocol.onUpdate

        OnDragStart args val ->
            U2.pure model
                |> U2.andThen (onDrag args val)
                |> protocol.onUpdate

        OnDrag args val _ ->
            U2.pure model
                |> U2.andThen (onDrag args val)
                |> protocol.onUpdate

        OnDragEnd args _ _ ->
            U2.pure model
                |> U2.andThen (onDragEnd args)
                |> protocol.onUpdate

        NextItem key ->
            U2.pure model
                |> U2.andThen (addConversationStep key False)
                |> U2.andThen nextWord
                |> U2.andThen showScrolledToPosition
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        TryOpen { elementId } ->
            U2.pure model
                |> U2.andThen (openConversationWithStep elementId)
                |> U2.andThen nextWord
                |> U2.andThen showScrolledToPosition
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        Toggle ->
            U2.pure { model | show = not model.show }
                |> U2.andThen openConversationIntroIfEmpty
                |> U2.andThen nextWord
                |> U2.andThen scrollToBottom
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        Close ->
            { model | show = False }
                |> U2.pure
                |> protocol.onUpdate

        ShowAll ->
            U2.pure { model | viewMode = ViewAll }
                |> U2.andThen showScrolledToPosition
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        EnterPrompt prompt ->
            U2.pure { model | prompt = prompt }
                |> protocol.onUpdate

        Submit prompt ->
            U2.pure model
                |> protocol.onUserPrompt prompt

        Noop ->
            U2.pure model
                |> protocol.onUpdate


addAIStep : Protocol (Update a) msg model -> Step -> Update a -> ( model, Cmd msg )
addAIStep protocol step model =
    U2.pure model
        |> U2.andThen (addConversationResponse step False)
        |> U2.andThen nextWord
        |> U2.andThen scrollToBottom
        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
        |> protocol.onUpdate


processResize : String -> VScene -> Update a -> ( Update a, Cmd Msg )
processResize id vec model =
    U2.pure model
        |> U2.andThen scrollToBottom


processSubmit : Update a -> ( Update a, Cmd Msg )
processSubmit model =
    let
        editorConfig =
            { editorId = "chatbox"
            , editorClass = "ia-chat-user-input"
            , textMarkdown = ""
            , viewStyles = { fontSize = 16 }
            , resizeDecoder = Resize.resizeDecoder
            , browserInfo = Unknown
            }

        item =
            ChatStep.stringTitleToItem OriginUser "prompt" model.prompt

        modelPromptToConversation =
            { model
                | chatSteps = ( "prompt", item, False ) :: model.chatSteps
                , prompt = ""
                , chatbox = Editor.init editorConfig Editor.NoSelection
            }
    in
    ( modelPromptToConversation
    , Submit model.prompt |> Task.Extra.message
    )
        |> U2.andThen scrollToBottom


processGesture : GestureLocation -> Pointer.Msg Value Screen -> Update a -> ( Update a, Cmd Msg )
processGesture loc pointerMsg model =
    let
        ( get, set ) =
            case loc of
                Doc ->
                    ( .gesturesOnDoc, \x m -> { m | gesturesOnDoc = x } )

                Div ->
                    ( .gesturesOnDiv, \x m -> { m | gesturesOnDiv = x } )

        ( newPointerModel, pointerCmds ) =
            get model |> Pointer.update pointerMsg
    in
    ( set newPointerModel model
    , pointerCmds
    )


onDrag : Pointer.DragArgs Screen -> Value -> Update a -> ( Update a, Cmd msg )
onDrag args val model =
    let
        pp =
            case model.gestureCondition of
                NoGesture ->
                    args.startPos

                Dragging { prevPos } ->
                    prevPos

        trans =
            Vector2d.from pp args.pos

        context =
            { model
                | gestureCondition = Dragging { prevPos = args.pos }
                , pos = Point2d.translateBy trans model.pos
            }
    in
    Decode.decodeValue
        (Decode.string
            |> Decode.andThen
                (\id ->
                    case id of
                        "ia-chat-topbar" ->
                            U2.pure context |> Decode.succeed

                        _ ->
                            U2.pure model |> Decode.succeed
                )
        )
        val
        |> Result.withDefault (U2.pure model)


onDragEnd : Pointer.DragArgs Screen -> Update a -> ( Update a, Cmd msg )
onDragEnd _ model =
    { model | gestureCondition = NoGesture }
        |> U2.pure


processAnimation : Float -> Update a -> ( Update a, Cmd msg )
processAnimation animTime model =
    case model.animation of
        Stopped ->
            U2.pure model

        Running delta ->
            U2.pure { model | animation = delta + animTime |> Running }
                |> U2.andThen
                    (\nextModel ->
                        if delta + animTime > 30 then
                            U2.pure { nextModel | animation = Running 0.0 }
                                |> U2.andThen nextWord

                        else
                            U2.pure nextModel
                    )


addConversationResponse : Step -> Bool -> Update a -> ( Update a, Cmd msg )
addConversationResponse step isNewTopic model =
    let
        response =
            case step of
                AIStep { content } ->
                    Just content

                _ ->
                    Nothing

        item =
            ( "response"
            , Maybe.withDefault "No response found!" response |> ChatStep.stringTitleToItem OriginAssistant "response"
            , isNewTopic
            )
                |> Just
    in
    case item of
        Just val ->
            ( { model | chatSteps = val :: model.chatSteps }
            , Cmd.none
            )

        Nothing ->
            U2.pure model


addConversationStep : String -> Bool -> Update a -> ( Update a, Cmd msg )
addConversationStep key isNewTopic model =
    model.decisionTree
        |> Maybe.andThen (Dict.get key)
        |> Maybe.map
            (\item ->
                ( { model | chatSteps = ( key, item, isNewTopic ) :: model.chatSteps }
                , Cmd.none
                )
            )
        |> Maybe.withDefault (U2.pure model)


openConversationIntroIfEmpty : Update a -> ( Update a, Cmd Msg )
openConversationIntroIfEmpty model =
    if List.isEmpty model.chatSteps then
        openConversationWithStep "intro" model

    else
        U2.pure model


openConversationWithStep : String -> Update a -> ( Update a, Cmd Msg )
openConversationWithStep key model =
    let
        viewPos =
            List.length model.chatSteps
    in
    case model.chatSteps of
        [] ->
            U2.pure
                { model
                    | viewMode = ViewFrom viewPos
                    , lastPosition = viewPos
                }
                |> U2.andThen (addConversationStep key True)

        ( head, _, _ ) :: _ ->
            if head == key then
                { model
                    | viewMode = ViewFrom model.lastPosition
                    , lastPosition = viewPos
                }
                    |> U2.pure

            else
                U2.pure
                    { model
                        | viewMode = ViewFrom viewPos
                        , lastPosition = viewPos
                    }
                    |> U2.andThen (addConversationStep key True)


{-| Process pending items into the current conversation, one word at a time. Replaying the
conversation a word at a time like this, enables the typing effect.

    - The animation timer for the typing effect is triggered by calling this, when there are pending
      items in the conversation still to process.

    - The animation timer for the typing effect is terminated by this, when the pending queue is empty.

-}
nextWord : Update a -> ( Update a, Cmd msg )
nextWord model =
    case model.chatSteps of
        [] ->
            U2.pure model

        ( key, item, isNewTopic ) :: cs ->
            let
                advanceInline inline =
                    case inline of
                        ChatStep.HRef _ ->
                            Nothing

                        ChatStep.Element _ ->
                            Nothing

                        ChatStep.Text buffer ->
                            GapBuffer.advanceFocus (always Nothing) buffer
                                |> Maybe.map ChatStep.Text

                advanceBody =
                    GapBuffer.advanceFocus
                        (\block ->
                            case block of
                                ChatStep.Body innerBody ->
                                    GapBuffer.advanceFocus advanceInline innerBody
                                        |> Maybe.map ChatStep.Body

                                ChatStep.Child _ ->
                                    Nothing
                        )
                        item.body
            in
            case advanceBody of
                Just nextBody ->
                    let
                        nextItem =
                            { item | body = nextBody }
                    in
                    ( { model
                        | chatSteps = ( key, nextItem, isNewTopic ) :: cs
                        , animation = Running 0.0
                      }
                    , Cmd.none
                    )

                Nothing ->
                    U2.pure { model | animation = Stopped }


showScrolledToPosition : Update a -> ( Update a, Cmd Msg )
showScrolledToPosition model =
    U2.pure { model | show = True }
        |> U2.andThen scrollToBottom


scrollToBottom : Update a -> ( Update a, Cmd Msg )
scrollToBottom model =
    ( model
    , Dom.getViewportOf "ia-chat-scroll"
        |> Task.andThen (\info -> Dom.setViewportOf "ia-chat-scroll" 0 info.scene.height)
        |> Task.attempt (\_ -> Noop)
    )
