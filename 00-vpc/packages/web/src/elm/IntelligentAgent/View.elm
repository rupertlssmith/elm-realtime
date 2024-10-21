module IntelligentAgent.View exposing (Actions, view)

import Array
import ChatBox.Editor as Editor
import Css
import Dict
import GapBuffer exposing (GapBuffer)
import Geometry exposing (PScreen, Screen)
import Html.Styled as HS exposing (Attribute, Html)
import Html.Styled.Attributes as HA
import Html.Styled.Events as HE
import Html.Styled.Lazy as Lazy
import Icon
import IntelligentAgent.ChatStep as ChatStep exposing (Block, Inline, Item, ItemOrigin(..))
import IntelligentAgent.DecisionTree exposing (DecisionTree)
import IntelligentAgent.Model exposing (ViewMode(..))
import IntelligentAgent.Msg exposing (Msg(..))
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Navigation exposing (Route(..))
import Pixels
import Point2d
import Pointer


type alias View a =
    { a
        | chatSteps : List ( String, Item, Bool )
        , show : Bool
        , gesturesOnDoc : Pointer.Model Value Msg Screen
        , viewMode : ViewMode
        , decisionTree : Maybe DecisionTree
        , pos : PScreen
        , chatbox : Editor.Model
    }


type alias Actions msg =
    { toMsg : Msg -> msg
    , pushUrl : Route -> msg
    }


view : Actions msg -> View a -> Html msg
view actions model =
    Lazy.lazy2 viewInner actions model


clickOutside : a -> Html a -> Html a
clickOutside msg body =
    HS.node "click-outside"
        [ HE.on "clickoutside" (Decode.succeed <| msg) ]
        [ body ]


viewInner : Actions msg -> View a -> Html msg
viewInner actions model =
    if model.show then
        HS.div
            [ HA.class "ia-frame" ]
            [ HS.div
                [ HA.class "ia-chat-container"
                , HA.css
                    [ Point2d.xCoordinate model.pos |> Pixels.toFloat |> Css.px |> Css.left
                    , Point2d.yCoordinate model.pos |> Pixels.toFloat |> Css.px |> Css.top
                    ]
                ]
                [ topBar actions model
                , HS.div
                    [ HA.class "ia-chat-scroll"
                    , HA.id "ia-chat-scroll"
                    ]
                    [ model.decisionTree
                        |> Maybe.map (\dt -> conversationToHtml actions model dt model.chatSteps)
                        |> Maybe.withDefault []
                        |> HS.div []
                    , chatBox actions model
                    ]
                ]
            ]

    else
        HS.div [] []


topBar : Actions msg -> View a -> Html msg
topBar actions model =
    HS.div
        [ HA.class "ia-chat-topbar"
        , HA.id "ia-chat-topbar"
        ]
        [ HS.div
            [ HA.class "ia-chat-icon"
            , HE.onClick ShowAll
            ]
            [ Icon.caretUpFill |> HS.fromUnstyled ]
        , HS.div
            [ HA.class "ia-chat-icon"
            , HE.onClick Close
            ]
            [ Icon.closex |> HS.fromUnstyled ]
        ]
        |> HS.map actions.toMsg


chatBox : Actions msg -> View a -> Html msg
chatBox actions model =
    HS.div [ HA.class "ia-chat" ]
        [ HS.div
            [ HA.class "ia-chat-icon" ]
            [ Icon.user |> HS.fromUnstyled ]
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
                        |> HS.map EditorMsg
                    ]
                ]
            ]
        ]
        |> HS.map actions.toMsg


conversationToHtml : Actions msg -> View a -> DecisionTree -> List ( String, Item, Bool ) -> List (Html msg)
conversationToHtml actions model tree conv =
    let
        convToShow =
            case model.viewMode of
                ViewAll ->
                    conv

                ViewFrom from ->
                    conv
                        |> List.reverse
                        |> List.drop from
                        |> List.reverse
    in
    List.foldr
        (\( _, item, newTopic ) accum ->
            if newTopic && List.length accum > 0 then
                itemToHtml actions model tree item :: HS.hr [] [] :: accum

            else
                itemToHtml actions model tree item :: accum
        )
        []
        convToShow
        |> List.reverse


itemToHtml : Actions msg -> View a -> DecisionTree -> Item -> Html msg
itemToHtml actions model tree item =
    let
        text =
            HS.div [ HA.class "ia-chat-text" ]
                [ HS.h5 [ HA.class "ia-chat-text-title" ] [ HS.text item.title ]
                , HS.div [ HA.class "ia-chat-text-body" ] (blocksToHtml actions model tree item.body)
                ]
    in
    case item.origin of
        OriginAssistant ->
            HS.div [ HA.class "ia-chat" ]
                [ HS.div
                    [ HA.class "ia-chat-icon"
                    , actions.pushUrl AgentTrace |> Navigation.click
                    ]
                    [ Icon.robot |> HS.fromUnstyled ]
                , text
                ]

        OriginUser ->
            HS.div [ HA.class "ia-chat" ]
                [ HS.div
                    [ HA.class "ia-chat-icon"
                    , actions.pushUrl AgentTrace |> Navigation.click
                    ]
                    [ Icon.user |> HS.fromUnstyled ]
                , text
                ]


blocksToHtml : Actions msg -> View a -> DecisionTree -> GapBuffer Block Block -> List (Html msg)
blocksToHtml actions model tree blocks =
    blocks
        |> availFromBuffer 1
        |> List.foldr (\block acc -> blockToHtml actions model tree block :: acc) []


blockToHtml : Actions msg -> View a -> DecisionTree -> Block -> Html msg
blockToHtml actions model tree block =
    case block of
        ChatStep.Body body ->
            body
                |> availFromBuffer 1
                |> List.foldr (\inline acc -> inlineToHtml model inline :: acc) []
                |> List.intersperse (HS.text " ")
                |> HS.p []

        ChatStep.Child child ->
            childTitleToHtml actions model tree child


inlineToHtml : View a -> Inline -> Html msg
inlineToHtml model inline =
    case inline of
        ChatStep.HRef { url, text } ->
            HS.a [ HA.href url ] [ HS.text text ]

        ChatStep.Element uuid ->
            elementAsToken model uuid

        ChatStep.Text val ->
            availFromBuffer 0 val |> String.join " " |> HS.text


elementAsToken : View a -> String -> Html msg
elementAsToken model uuid =
    HS.div [] []


childTitleToHtml : Actions msg -> View a -> DecisionTree -> String -> Html msg
childTitleToHtml actions model tree key =
    Dict.get key tree
        |> Maybe.map
            (\item ->
                HS.div
                    ((Pointer.on model.gesturesOnDoc
                        (\_ -> Decode.succeed (Encode.object [ ( "textMarkdown", Encode.string item.title ) ]))
                        |> List.map HA.fromUnstyled
                     )
                        ++ [ HA.class "ia-chat-text-child"
                           , NextItem key |> HE.onClick
                           , HA.attribute "draggable" "false"
                           , HE.preventDefaultOn "dragstart" (Decode.succeed ( Noop, True ))
                           ]
                    )
                    [ HS.div [ HA.class "ia-chat-text-child-icon" ]
                        [ Icon.caretRightFill |> HS.fromUnstyled ]
                    , HS.a [] [ HS.text item.title ]
                    ]
            )
        |> Maybe.withDefault (HS.text "not found")
        |> HS.map actions.toMsg


availFromBuffer : Int -> GapBuffer a b -> List a
availFromBuffer lookAhead buffer =
    let
        pos =
            GapBuffer.currentFocus buffer
                |> Maybe.map Tuple.first
                |> Maybe.withDefault (GapBuffer.length buffer)
    in
    GapBuffer.slice 0 (pos + lookAhead) buffer
        |> Array.toList
