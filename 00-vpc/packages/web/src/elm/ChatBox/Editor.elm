module ChatBox.Editor exposing
    ( Model, Msg, Protocol, init, update, view
    , Config, ViewStyles
    , Style(..), BlockStyle(..)
    , ControlContext
    , StyleStatus(..)
    , Selection(..)
    )

{-|


# TEA model.

@docs Model, Msg, Protocol, init, update, view


# Configuration

@docs Config, ViewStyles


# Available inline or block styles .

@docs Style, BlockStyle


# Control actions.


# Context to assist with correctly rendering and applying control actions.

@docs ControlContext
@docs StyleStatus


# Cursor control and reporting.

@docs Selection

-}

import Array exposing (Array)
import BrowserInfo exposing (BrowserInfo)
import Geometry exposing (VScene)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Markdown.Block as Block
import Markdown.Config
import Markdown.Inline as Inline
import RichText.Commands as Commands
import RichText.Config.Command as Command exposing (CommandMap)
import RichText.Config.Decorations as Decorations exposing (Decorations)
import RichText.Config.ElementDefinition as ElementDefinition exposing (ElementDefinition, ElementToHtml, HtmlToElement)
import RichText.Config.Keys as Keys
import RichText.Config.Spec as Spec exposing (Spec)
import RichText.Definitions as Definitions
import RichText.Editor as Editor exposing (Editor, Message)
import RichText.List as RTList
import RichText.Model.Attribute as Attribute
import RichText.Model.Element as Element exposing (Element)
import RichText.Model.History as History
import RichText.Model.HtmlNode exposing (HtmlNode(..))
import RichText.Model.InlineElement as InlineElement
import RichText.Model.Mark as Mark exposing (Mark, MarkOrder)
import RichText.Model.Node as ModelNode exposing (Block, Children, Inline, InlineTree, Path)
import RichText.Model.Selection as Selection
import RichText.Model.State as State exposing (State)
import RichText.Model.Text as Text
import RichText.Node as Node exposing (Node)
import Set exposing (Set)
import Task.Extra
import Update2 as U2


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onResize : String -> VScene -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onSubmit : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


type alias Model =
    { editor : Editor
    , styles : List Style
    , textMarkdown : String
    , markdownError : Maybe String
    , id : String
    , spec : Spec
    , config : Config
    }


type alias Config =
    { editorId : String
    , editorClass : String
    , textMarkdown : String
    , viewStyles : ViewStyles
    , resizeDecoder : Decoder VScene
    , browserInfo : BrowserInfo
    }


type alias ViewStyles =
    { fontSize : Float
    }


type Msg
    = InternalMsg Message
    | EditorResize String VScene
    | Submit


type Style
    = Bold
    | Italic


type BlockStyle
    = CodeBlock
    | Heading Int


type alias ControlContext =
    { hasInline : Bool
    , selection : Selection
    , hasUndo : Bool
    , hasRedo : Bool
    , nodes : Set String
    , marks : Set String
    , canLift : Bool
    }


type Selection
    = NoSelection
    | Collapsed
        { offset : Int
        , node : List Int
        }
    | Range
        { anchorOffset : Int
        , anchorNode : List Int
        , focusOffset : Int
        , focusNode : List Int
        }


editorConfig : Config -> Editor.Config Msg
editorConfig config =
    Editor.config
        { decorations = decorations config
        , commandMap = commandBindings config Definitions.markdown
        , spec =
            Definitions.markdown
                |> Spec.withElementDefinitions
                    [ wrapperNode
                    , Definitions.paragraph

                    --, Definitions.blockquote
                    --, Definitions.horizontalRule
                    --, Definitions.heading
                    --, Definitions.codeBlock
                    --, Definitions.image
                    --, Definitions.hardBreak
                    --, Definitions.unorderedList
                    --, Definitions.orderedList
                    --, Definitions.listItem
                    ]
        , toMsg = InternalMsg
        }


defaultInitialState : Selection -> State
defaultInitialState sel =
    let
        docInitNode : Block
        docInitNode =
            ModelNode.block
                (Element.element Definitions.doc [])
                (ModelNode.blockChildren (Array.fromList [ initialEditorNode ]))

        initialEditorNode : Block
        initialEditorNode =
            ModelNode.block
                (Element.element Definitions.paragraph [])
                (ModelNode.inlineChildren (Array.fromList [ ModelNode.plainText "Sticky Note" ]))
    in
    State.state docInitNode
        (localSelectionToRteSelection sel)


initialStateFromMarkdown : String -> Selection -> Result String State
initialStateFromMarkdown textMarkdown sel =
    let
        parseMarkdown val =
            Block.parse
                (Just
                    { softAsHardLineBreak = False
                    , rawHtml = Markdown.Config.DontParse
                    }
                )
                val
    in
    textMarkdown
        |> parseMarkdown
        |> filterBlankLines
        |> markdownToBlock
        |> Result.map (\doc -> State.state doc (localSelectionToRteSelection sel))


listCommandBindings : CommandMap
listCommandBindings =
    RTList.defaultCommandMap RTList.defaultListDefinition


emptyParagraph : Block
emptyParagraph =
    ModelNode.block
        (Element.element Definitions.paragraph [])
        (Array.fromList [ ModelNode.plainText "" ] |> ModelNode.inlineChildren)


commandBindings : Config -> Spec -> CommandMap
commandBindings config commandSpec =
    let
        markOrder =
            Mark.markOrderFromSpec commandSpec

        firefoxSpaceCmd =
            case config.browserInfo of
                BrowserInfo.Firefox ->
                    Command.set [ Command.inputEvent "insertSpace", Command.key [ " " ] ]
                        [ ( "insertSpace"
                          , Commands.insertText "\u{205F}"
                                |> Command.transform
                          )
                        ]

                _ ->
                    identity
    in
    Command.combine
        listCommandBindings
        (Commands.defaultCommandMap
            |> Command.set
                [ Command.inputEvent "insertParagraph"
                , Command.key [ Keys.enter ]
                , Command.key [ Keys.return ]
                ]
                []
            |> Command.set
                [ Command.key [ Keys.shift, Keys.enter ]
                , Command.key [ Keys.shift, Keys.return ]
                ]
                [ ( "insertNewline"
                  , Commands.insertNewline [ "code_block" ]
                        |> Command.transform
                  )
                , ( "liftEmpty"
                  , Commands.liftEmpty
                        |> Command.transform
                  )
                , ( "splitBlockHeaderToNewParagraph"
                  , Commands.splitBlockHeaderToNewParagraph [ "heading" ] (Element.element Definitions.paragraph [])
                        |> Command.transform
                  )
                , ( "insertEmptyParagraph"
                  , Commands.insertAfterBlockLeaf emptyParagraph
                        |> Command.transform
                  )
                ]
            |> firefoxSpaceCmd
            |> Command.set
                [ Command.inputEvent "formatBold"
                , Command.key [ Keys.short, "b" ]
                ]
                [ ( "toggleStyle"
                  , Commands.toggleMark markOrder (Mark.mark Definitions.bold []) Mark.Flip
                        |> Command.transform
                  )
                ]
            |> Command.set
                [ Command.inputEvent "formatItalic"
                , Command.key [ Keys.short, "i" ]
                ]
                [ ( "toggleStyle"
                  , Commands.toggleMark markOrder (Mark.mark Definitions.italic []) Mark.Flip
                        |> Command.transform
                  )
                ]
        )



-- Custom Elements and Decorations


decorations : Config -> Decorations Msg
decorations config =
    Decorations.emptyDecorations
        --|> Decorations.addElementDecoration Definitions.image (Decorations.selectableDecoration InternalMsg)
        --|> Decorations.addElementDecoration Definitions.horizontalRule (Decorations.selectableDecoration InternalMsg)
        |> Decorations.withTopLevelAttributes
            [ -- Disable the grammarly plugin as it breaks the virtual dom.
              HA.attribute "data-gramm_editor" "false"

            -- Prevent Firefox from spellchecking and underlining words mispelled.
            , HA.attribute "spellcheck" "false"
            , HA.id config.editorId
            , HA.class config.editorClass
            , HA.style "justify-content" "flex-start"
            ]
        |> Decorations.addElementDecoration wrapperNode (wrapperDecoration config)


wrapperDecoration : Config -> Decorations.ElementDecoration Msg
wrapperDecoration config _ _ path =
    case path of
        [] ->
            [ HA.style "font-size" (String.fromFloat config.viewStyles.fontSize ++ "px") |> Just
            , HA.id ("resize-sticky-" ++ config.editorId) |> Just
            , HE.stopPropagationOn "resize" (config.resizeDecoder |> Decode.map (\vscene -> ( EditorResize config.editorId vscene, True ))) |> Just
            ]
                |> List.filterMap identity

        _ ->
            []


wrapperNode : ElementDefinition
wrapperNode =
    ElementDefinition.elementDefinition
        { name = "doc"
        , group = "root"
        , contentType = ElementDefinition.blockNode [ "block" ]
        , toHtmlNode = wrapperToHtml
        , fromHtmlNode = htmlToWrapper
        , selectable = False
        }


wrapperToHtml : ElementToHtml
wrapperToHtml _ children =
    ElementNode "elm-resize"
        [ ( "class", "content-main editableElement" )
        ]
        (Array.fromList
            [ ElementNode "div"
                [ ( "data-rte-doc", "true" ) ]
                children
            ]
        )


htmlToWrapper : HtmlToElement
htmlToWrapper definition node =
    case node of
        ElementNode name attrs children ->
            if name == "div" && attrs == [ ( "data-rte-doc", "true" ) ] then
                Just <| ( Element.element definition [], children )

            else
                Nothing

        _ ->
            Nothing



-- ========


init : Config -> Selection -> Model
init config sel =
    let
        ( initialState, error ) =
            case initialStateFromMarkdown config.textMarkdown sel of
                Ok state ->
                    ( state, Nothing )

                Err err ->
                    ( defaultInitialState sel, Just err )
    in
    { editor = initialState |> Editor.init
    , styles = [ Bold, Italic ]
    , textMarkdown = config.textMarkdown
    , markdownError = error
    , id = config.editorId
    , spec = editorConfig config |> Editor.spec
    , config = config
    }


editorUpdate : Editor.Config msg -> Editor.Message -> Editor -> ( Editor, Cmd Editor.Message )
editorUpdate cfg msg ed =
    ( Editor.update cfg msg ed, Cmd.none )


update : Protocol Model msg model -> Msg -> Model -> ( model, Cmd msg )
update protocol msg model =
    case msg of
        InternalMsg internalEditorMsg ->
            model
                |> U2.lift .editor (\x m -> { m | editor = x }) InternalMsg (editorUpdate (editorConfig model.config)) internalEditorMsg
                |> U2.andThen extractMarkdown
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        EditorResize id vec ->
            U2.pure model
                |> protocol.onResize id vec

        Submit ->
            U2.pure model
                |> protocol.onSubmit


extractMarkdown : Model -> ( Model, Cmd Msg )
extractMarkdown model =
    let
        markdownNodes =
            rootToMarkdown (State.root (Editor.state model.editor))

        ( result, error ) =
            case Result.andThen markdownToString markdownNodes of
                Err e ->
                    ( model.textMarkdown, Just e )

                Ok m ->
                    ( m, Nothing )
    in
    case error of
        Just e ->
            ( { model | markdownError = Just e }, Cmd.none )

        Nothing ->
            ( { model
                | textMarkdown = result
                , markdownError = Nothing
              }
            , Cmd.none
            )


setSelection : Selection -> Model -> Model
setSelection sel model =
    { model
        | editor =
            Editor.state model.editor
                |> State.withSelection (localSelectionToRteSelection sel)
                |> Editor.init
    }


toggleStyle : Style -> Model -> Model
toggleStyle style model =
    let
        markDef =
            case style of
                Bold ->
                    Definitions.bold

                Italic ->
                    Definitions.italic

        markOrder =
            Mark.markOrderFromSpec model.spec
    in
    { model
        | editor =
            Result.withDefault model.editor
                (Editor.apply
                    ( "toggleStyle"
                    , Commands.toggleMark markOrder (Mark.mark markDef []) Mark.Flip
                        |> Command.transform
                    )
                    model.spec
                    model.editor
                )
    }


toggleBlockStyle : BlockStyle -> Model -> Model
toggleBlockStyle blockStyle model =
    let
        onParams =
            case blockStyle of
                CodeBlock ->
                    Element.element
                        Definitions.codeBlock
                        []

                Heading level ->
                    Element.element
                        Definitions.heading
                        [ Attribute.IntegerAttribute
                            "level"
                            level
                        ]

        offParams =
            Element.element Definitions.paragraph []

        convertToPlainText =
            blockStyle == CodeBlock
    in
    { model
        | editor =
            Result.withDefault model.editor
                (Editor.apply
                    ( "toggleBlock"
                    , Commands.toggleTextBlock onParams offParams convertToPlainText |> Command.transform
                    )
                    model.spec
                    model.editor
                )
    }


view : ViewStyles -> Model -> Html Msg
view viewStyles model =
    let
        modelWithViewStyles =
            let
                innerConfig =
                    model.config
            in
            { model | config = { innerConfig | viewStyles = viewStyles } }
    in
    Html.div
        [ HA.style "width" "100%"
        , HE.stopPropagationOn "keydown" enterDecoder
        ]
        [ Editor.view (editorConfig modelWithViewStyles.config) modelWithViewStyles.editor
        ]


enterDecoder : Decoder ( Msg, Bool )
enterDecoder =
    Decode.succeed Tuple.pair
        |> DE.andMap (Decode.field "key" Decode.string)
        |> DE.andMap (Decode.field "shiftKey" Decode.bool)
        |> Decode.andThen
            (\( val, shift ) ->
                case ( val, shift ) of
                    ( "Enter", False ) ->
                        ( Submit, True ) |> Decode.succeed

                    ( "Return", False ) ->
                        ( Submit, True ) |> Decode.succeed

                    _ ->
                        Decode.fail ""
            )



--- Controls


emptyControlState : ControlContext
emptyControlState =
    { hasUndo = False
    , hasRedo = False
    , hasInline = False
    , selection = NoSelection
    , nodes = Set.empty
    , marks = Set.empty
    , canLift = False
    }


accumulateControlState : Node -> ControlContext -> ControlContext
accumulateControlState node controlState =
    case node of
        Node.Block n ->
            { controlState
                | nodes =
                    Set.insert (Element.name (ModelNode.element n)) controlState.nodes
            }

        Node.Inline inline ->
            let
                names =
                    List.map Mark.name (ModelNode.marks inline)
            in
            { controlState
                | hasInline = True
                , marks = Set.union (Set.fromList names) controlState.marks
            }


accumulateControlStateWithRanges : List ( Path, Path ) -> Block -> ControlContext -> ControlContext
accumulateControlStateWithRanges ranges root controlState =
    List.foldl
        (\( start, end ) cs ->
            Node.foldlRange start
                end
                accumulateControlState
                cs
                root
        )
        controlState
        ranges


getControlContext : Model -> ControlContext
getControlContext model =
    let
        state_ =
            Editor.state model.editor

        history_ =
            Editor.history model.editor
    in
    case State.selection state_ of
        Nothing ->
            emptyControlState

        Just selection ->
            let
                hasUndo =
                    History.peek history_ /= Nothing

                hasRedo =
                    List.isEmpty (History.redoList history_) |> not

                normalizedSelection =
                    selection |> Selection.normalize

                parentFocus =
                    ModelNode.parent (Selection.focusNode normalizedSelection)

                parentAnchor =
                    ModelNode.parent (Selection.anchorNode normalizedSelection)

                controlState =
                    accumulateControlStateWithRanges
                        [ ( Selection.anchorNode normalizedSelection
                          , Selection.focusNode normalizedSelection
                          )
                        , ( parentFocus, parentFocus )
                        , ( parentAnchor, parentAnchor )
                        ]
                        (State.root state_)
                        { emptyControlState
                            | selection = normalizedSelection |> rteSelectionToLocalSelection
                        }
            in
            { controlState
                | canLift =
                    -- This is hacky, but we'll assume we can lift anything that's nested
                    -- three or more nodes deep.
                    (List.length (Selection.anchorNode normalizedSelection) > 2)
                        || (List.length (Selection.focusNode normalizedSelection) > 2)
                        || Set.member "blockquote" controlState.nodes
                        || Set.member "li" controlState.nodes
                , hasUndo = hasUndo
                , hasRedo = hasRedo
            }


rteSelectionToLocalSelection : Selection.Selection -> Selection
rteSelectionToLocalSelection sel =
    let
        anchorNode =
            Selection.anchorNode sel

        anchorOffset =
            Selection.anchorOffset sel

        focusNode =
            Selection.focusNode sel

        focusOffset =
            Selection.focusOffset sel
    in
    if anchorNode == focusNode && anchorOffset == focusOffset then
        Collapsed
            { node = anchorNode
            , offset = anchorOffset
            }

    else
        Range
            { anchorNode = anchorNode
            , anchorOffset = anchorOffset
            , focusNode = focusNode
            , focusOffset = focusOffset
            }


localSelectionToRteSelection : Selection -> Maybe Selection.Selection
localSelectionToRteSelection sel =
    case sel of
        NoSelection ->
            Nothing

        Collapsed args ->
            Selection.caret
                args.node
                args.offset
                |> Just

        Range args ->
            Selection.range
                args.anchorNode
                args.anchorOffset
                args.focusNode
                args.focusOffset
                |> Just



-- Query the Control Status


type StyleStatus
    = Active
    | Enabled
    | Disabled


{-| Provides status information on what styles are active within the current selection
of the control context.
-}
statusForStyle : Style -> ControlContext -> StyleStatus
statusForStyle style controlState =
    if Set.member (styleToString style) controlState.marks then
        Active

    else
        Enabled


styleToString : Style -> String
styleToString style =
    case style of
        Bold ->
            "bold"

        Italic ->
            "italic"



-- Markdown AST


type alias CustomInline =
    {}


type alias CustomBlock =
    {}


type alias MBlock =
    Block.Block CustomBlock CustomInline


type alias MInline =
    Inline.Inline CustomInline


markdownMarkOrder : MarkOrder
markdownMarkOrder =
    Mark.markOrderFromSpec Definitions.markdown



-- Convert markdown AST to RTE Toolkit blocks.


unwrapAndFilterChildNodes : List (Result String a) -> Result String (List a)
unwrapAndFilterChildNodes results =
    let
        unwrappedResults =
            List.filterMap
                (\x ->
                    case x of
                        Ok v ->
                            Just v

                        _ ->
                            Nothing
                )
                results
    in
    if List.length unwrappedResults == List.length results then
        Ok unwrappedResults

    else
        Err <|
            String.join "\n" <|
                List.filterMap
                    (\x ->
                        case x of
                            Err s ->
                                Just s

                            _ ->
                                Nothing
                    )
                    results


blockChildrenToMarkdown : Children -> Result String (List MBlock)
blockChildrenToMarkdown cn =
    case cn of
        ModelNode.BlockChildren a ->
            let
                results =
                    List.map blockToMarkdown (Array.toList (ModelNode.toBlockArray a))
            in
            unwrapAndFilterChildNodes results

        ModelNode.InlineChildren _ ->
            Err "Invalid child nodes, received inline, expected block"

        ModelNode.Leaf ->
            Err "Invalid child nodes, received leaf, expected block"


inlineChildrenToMarkdown : Children -> Result String (List MInline)
inlineChildrenToMarkdown cn =
    case cn of
        ModelNode.InlineChildren a ->
            let
                results =
                    List.map (inlineToMarkdown (ModelNode.toInlineArray a)) (Array.toList (ModelNode.toInlineTree a))
            in
            Result.map (List.concatMap identity) (unwrapAndFilterChildNodes results)

        ModelNode.BlockChildren _ ->
            Err "Invalid child nodes, was expected inline, received block"

        ModelNode.Leaf ->
            Err "Invalid child nodes, was expected inline, received leaf"


rootToMarkdown : Block -> Result String (List MBlock)
rootToMarkdown node =
    node
        |> ModelNode.childNodes
        |> blockChildrenToMarkdown


imageToMarkdown : Element -> Result String MInline
imageToMarkdown parameters =
    let
        attributes =
            Element.attributes parameters

        alt =
            Attribute.findStringAttribute "alt" attributes
    in
    case Attribute.findStringAttribute "src" attributes of
        Nothing ->
            Err "No src attribute found"

        Just src ->
            Ok <| Inline.Image src alt []


inlineToMarkdown : Array Inline -> InlineTree -> Result String (List MInline)
inlineToMarkdown leaves tree =
    case tree of
        ModelNode.LeafNode i ->
            case Array.get i leaves of
                Nothing ->
                    Err "Invalid leaf tree"

                Just inlineLeaf ->
                    case inlineLeaf of
                        ModelNode.Text p ->
                            Ok <| [ Inline.Text (Text.text p) ]

                        ModelNode.InlineElement il ->
                            let
                                parameters =
                                    InlineElement.element il
                            in
                            case Element.name parameters of
                                "image" ->
                                    Result.map List.singleton (imageToMarkdown parameters)

                                "hard_break" ->
                                    Ok <| [ Inline.HardLineBreak ]

                                name ->
                                    Err <| "Unsupported inline leaf :" ++ name

        ModelNode.MarkNode m ->
            case unwrapAndFilterChildNodes <| List.map (inlineToMarkdown leaves) (Array.toList m.children) of
                Err s ->
                    Err s

                Ok children ->
                    let
                        flattenedChildren =
                            List.concatMap identity children
                    in
                    case Mark.name m.mark of
                        "bold" ->
                            [ Inline.Emphasis 2 flattenedChildren ]
                                |> Ok

                        "italic" ->
                            Ok <| [ Inline.Emphasis 1 flattenedChildren ]

                        "code" ->
                            Ok <|
                                List.map
                                    (\x ->
                                        case x of
                                            Inline.Text s ->
                                                Inline.CodeInline s

                                            _ ->
                                                x
                                    )
                                    flattenedChildren

                        "link" ->
                            let
                                attributes =
                                    Mark.attributes m.mark

                                title =
                                    Attribute.findStringAttribute "title" attributes
                            in
                            case Attribute.findStringAttribute "href" attributes of
                                Nothing ->
                                    Err "Invalid link mark"

                                Just href ->
                                    Ok <| [ Inline.Link href title flattenedChildren ]

                        name ->
                            Err <| "Unsupported mark: " ++ name


textFromChildNodes : Children -> String
textFromChildNodes cn =
    case cn of
        ModelNode.InlineChildren il ->
            String.join "" <|
                Array.toList <|
                    Array.map
                        (\l ->
                            case l of
                                ModelNode.Text tl ->
                                    Text.text tl

                                ModelNode.InlineElement p ->
                                    if
                                        Element.name
                                            (InlineElement.element p)
                                            == "hard_break"
                                    then
                                        "\n"

                                    else
                                        ""
                        )
                        (ModelNode.toInlineArray il)

        _ ->
            ""


headingToMarkdown : Element -> Children -> Result String MBlock
headingToMarkdown p cn =
    let
        attributes =
            Element.attributes p

        level =
            Maybe.withDefault 1 (Attribute.findIntegerAttribute "level" attributes)
    in
    Result.map (Block.Heading "" level) (inlineChildrenToMarkdown cn)


codeBlockToMarkdown : Children -> Result String MBlock
codeBlockToMarkdown cn =
    let
        t =
            textFromChildNodes cn
    in
    Ok <| Block.CodeBlock Block.Indented t


listToMarkdown : Block.ListType -> Element -> Children -> Result String MBlock
listToMarkdown type_ parameters cn =
    let
        defaultDelimiter =
            case type_ of
                Block.Unordered ->
                    "*"

                Block.Ordered _ ->
                    "."

        delimiter =
            Maybe.withDefault defaultDelimiter <|
                Attribute.findStringAttribute
                    "delimiter"
                    (Element.attributes parameters)

        listItems =
            case cn of
                ModelNode.BlockChildren a ->
                    let
                        children =
                            Array.toList <| ModelNode.toBlockArray a
                    in
                    unwrapAndFilterChildNodes <|
                        List.map
                            (\x ->
                                blockChildrenToMarkdown (ModelNode.childNodes x)
                            )
                            children

                _ ->
                    Err <| "Invalid list items"
    in
    case listItems of
        Err s ->
            Err s

        Ok lis ->
            Ok <|
                Block.List
                    { type_ = type_
                    , indentLength = 3
                    , delimiter = delimiter
                    , isLoose = False
                    }
                    lis


blockToMarkdown : Block -> Result String MBlock
blockToMarkdown node =
    let
        parameters =
            ModelNode.element node

        children =
            ModelNode.childNodes node
    in
    case Element.name parameters of
        "paragraph" ->
            Result.map (Block.Paragraph "") (inlineChildrenToMarkdown children)

        "blockquote" ->
            Result.map Block.BlockQuote (blockChildrenToMarkdown children)

        "horizontal_rule" ->
            Ok Block.ThematicBreak

        "heading" ->
            headingToMarkdown parameters children

        "code_block" ->
            codeBlockToMarkdown children

        "unordered_list" ->
            listToMarkdown Block.Unordered parameters children

        "ordered_list" ->
            listToMarkdown (Block.Ordered 1) parameters children

        name ->
            Err ("Unexpected element: " ++ name)



-- Convert RTE Toolkit blocks to string formatted markdown.


markdownToString : List MBlock -> Result String String
markdownToString blocks =
    blockMarkdownChildrenToString blocks


escapeForMarkdown : String -> String
escapeForMarkdown s =
    s


inlineMarkdownToString : MInline -> Result String String
inlineMarkdownToString inline =
    case inline of
        Inline.Text s ->
            Ok <| escapeForMarkdown s

        Inline.HardLineBreak ->
            Ok "  \n"

        Inline.CodeInline s ->
            Ok <| "`" ++ s ++ "`"

        Inline.Link href title children ->
            Result.map
                (\c ->
                    let
                        t =
                            Maybe.withDefault "" <| Maybe.map (\m -> " \"" ++ m ++ "\"") title
                    in
                    "[" ++ c ++ "](" ++ href ++ t ++ ")"
                )
                (inlineMarkdownChildrenToString children)

        Inline.Image url alt children ->
            Result.map
                (\c ->
                    let
                        a =
                            Maybe.withDefault "" <| Maybe.map (\m -> " \"" ++ m ++ "\"") alt
                    in
                    "![" ++ c ++ "](" ++ url ++ a ++ ")"
                )
                (inlineMarkdownChildrenToString children)

        Inline.Emphasis length children ->
            let
                e =
                    String.repeat length "*"

                endsWithSpace s =
                    String.endsWith "\u{00A0}" s
                        || String.endsWith " " s
                        || String.endsWith "\u{205F}" s

                shiftSpaces ( s, spaces ) =
                    if endsWithSpace s then
                        ( String.left (String.length s - 1) s, "\u{00A0}" ++ spaces )
                            |> shiftSpaces

                    else
                        ( s, spaces )

                endSpacesOutsideEmph s =
                    if s == "" then
                        s

                    else if endsWithSpace s then
                        let
                            ( withoutEndSpaces, spaces ) =
                                shiftSpaces ( s, "" )
                        in
                        e ++ withoutEndSpaces ++ e ++ spaces

                    else
                        e ++ s ++ e
            in
            inlineMarkdownChildrenToString children
                |> Result.map endSpacesOutsideEmph

        Inline.HtmlInline _ _ _ ->
            Err "Html inline is not implemented."

        Inline.Custom _ _ ->
            Err "Custom elements are not implemented"


inlineMarkdownChildrenToString : List MInline -> Result String String
inlineMarkdownChildrenToString inlines =
    Result.map (String.join "") <|
        unwrapAndFilterChildNodes <|
            List.map inlineMarkdownToString inlines


blockMarkdownChildrenToString : List MBlock -> Result String String
blockMarkdownChildrenToString blocks =
    Result.map (String.join "\n") <|
        unwrapAndFilterChildNodes (List.map markdownBlockToString blocks)


indentEverythingButFirstLine : Int -> String -> String
indentEverythingButFirstLine n s =
    String.join "\n" <|
        List.indexedMap
            (\i x ->
                if i == 0 then
                    x

                else
                    String.repeat n " " ++ x
            )
            (String.split "\n" s)


listMarkdownToString : Block.ListBlock -> List (List MBlock) -> Result String String
listMarkdownToString listBlock listItems =
    Result.map
        (\children ->
            String.join "\n"
                (List.indexedMap
                    (\i z ->
                        let
                            prefix =
                                case listBlock.type_ of
                                    Block.Unordered ->
                                        listBlock.delimiter ++ " "

                                    Block.Ordered startIndex ->
                                        String.fromInt (startIndex + i) ++ listBlock.delimiter ++ " "
                        in
                        prefix ++ indentEverythingButFirstLine (String.length prefix) z
                    )
                    children
                )
        )
        (unwrapAndFilterChildNodes <|
            List.map blockMarkdownChildrenToString listItems
        )


markdownCodeBlockToString : Block.CodeBlock -> String -> Result String String
markdownCodeBlockToString cb s =
    case cb of
        Block.Fenced _ fence ->
            let
                delimeter =
                    String.repeat fence.fenceLength fence.fenceChar
            in
            Ok <|
                (delimeter ++ "\n")
                    ++ String.join "\n" (List.map (\v -> String.repeat fence.indentLength " " ++ v) (String.split "\n" s))
                    ++ ("\n" ++ delimeter)

        Block.Indented ->
            Ok <| String.join "\n" <| List.map (\v -> "    " ++ v) (String.split "\n" s)


markdownBlockToString : MBlock -> Result String String
markdownBlockToString block =
    case block of
        Block.BlankLine s ->
            Ok <| s

        Block.ThematicBreak ->
            Ok <| "---"

        Block.Heading _ i children ->
            Result.map
                (\x -> String.repeat i "#" ++ " " ++ x)
                (inlineMarkdownChildrenToString children)

        Block.CodeBlock cb s ->
            markdownCodeBlockToString cb s

        Block.Paragraph _ children ->
            Result.map (\x -> x ++ "\n") <|
                inlineMarkdownChildrenToString children

        Block.BlockQuote children ->
            Result.map
                (\x ->
                    String.join "\n" (List.map (\m -> "> " ++ m) (String.split "\n" x))
                )
                (blockMarkdownChildrenToString children)

        Block.List lb listItems ->
            listMarkdownToString lb listItems

        Block.PlainInlines children ->
            inlineMarkdownChildrenToString children

        Block.Custom _ _ ->
            Err "Custom element are not implemented"


markdownToBlock : List MBlock -> Result String Block
markdownToBlock md =
    Result.map
        (\children ->
            ModelNode.block
                (Element.element Definitions.doc [])
                children
        )
        (markdownBlockListToBlockChildNodes md)


markdownBlockListToBlockChildNodes : List MBlock -> Result String Children
markdownBlockListToBlockChildNodes blocks =
    Result.map
        (\items -> ModelNode.blockChildren (Array.fromList items))
        (markdownBlockListToBlockLeaves blocks)


markdownBlockListToBlockLeaves : List MBlock -> Result String (List Block)
markdownBlockListToBlockLeaves blocks =
    unwrapAndFilterChildNodes (List.map markdownBlockToEditorBlock blocks)


markdownInlineListToInlineChildNodes : List MInline -> Result String Children
markdownInlineListToInlineChildNodes inlines =
    Result.map
        (\items -> ModelNode.inlineChildren (Array.fromList items))
        (markdownInlineListToInlineLeaves [] inlines)


markdownInlineListToInlineLeaves : List Mark -> List MInline -> Result String (List Inline)
markdownInlineListToInlineLeaves marks inlines =
    Result.map
        (\items -> List.concatMap identity items)
        (unwrapAndFilterChildNodes (List.map (markdownInlineToInlineLeaves marks) inlines))


markdownInlineToInlineLeaves : List Mark -> MInline -> Result String (List Inline)
markdownInlineToInlineLeaves marks inline =
    case inline of
        Inline.Text s ->
            Ok <|
                [ ModelNode.markedText s (Mark.sort markdownMarkOrder marks) ]

        Inline.HardLineBreak ->
            Ok <|
                [ ModelNode.inlineElement (Element.element Definitions.hardBreak []) [] ]

        Inline.CodeInline s ->
            let
                codeMark =
                    Mark.mark Definitions.code []
            in
            Ok <| [ ModelNode.markedText s (Mark.sort markdownMarkOrder (codeMark :: marks)) ]

        Inline.Link href title children ->
            let
                linkMark =
                    Mark.mark Definitions.link
                        (List.filterMap identity
                            [ Just <| Attribute.StringAttribute "href" href
                            , Maybe.map (\t -> Attribute.StringAttribute "title" t) title
                            ]
                        )
            in
            markdownInlineListToInlineLeaves (linkMark :: marks) children

        Inline.Image src alt _ ->
            let
                inlineImage =
                    ModelNode.inlineElement
                        (Element.element Definitions.image
                            (List.filterMap identity
                                [ Just <| Attribute.StringAttribute "src" src
                                , Maybe.map (\t -> Attribute.StringAttribute "alt" t) alt
                                ]
                            )
                        )
                        (Mark.sort markdownMarkOrder marks)
            in
            Ok <| [ inlineImage ]

        Inline.Emphasis i children ->
            let
                emphasis =
                    case i of
                        1 ->
                            [ Mark.mark Definitions.italic [] ]

                        2 ->
                            [ Mark.mark Definitions.bold [] ]

                        3 ->
                            [ Mark.mark Definitions.bold [], Mark.mark Definitions.italic [] ]

                        _ ->
                            []
            in
            markdownInlineListToInlineLeaves (emphasis ++ marks) children

        Inline.HtmlInline _ _ _ ->
            Err "Not implemented"

        Inline.Custom _ _ ->
            Err "Not implemented"


markdownCodeBlockToEditorBlock : Block.CodeBlock -> String -> Result String Block
markdownCodeBlockToEditorBlock cb s =
    let
        attributes =
            case cb of
                Block.Indented ->
                    [ Attribute.StringAttribute "type" "indented" ]

                Block.Fenced b f ->
                    List.filterMap identity
                        [ Just <| Attribute.BoolAttribute "open" b
                        , Just <| Attribute.StringAttribute "type" "fenced"
                        , Just <| Attribute.IntegerAttribute "indentLength" f.indentLength
                        , Just <| Attribute.IntegerAttribute "fenceLength" f.fenceLength
                        , Maybe.map (\m -> Attribute.StringAttribute "language" m) f.language
                        ]
    in
    Ok <|
        ModelNode.block
            (Element.element Definitions.codeBlock attributes)
            (ModelNode.inlineChildren <| Array.fromList [ ModelNode.plainText s ])


markdownListToEditorBlock : Block.ListBlock -> List (List MBlock) -> Result String Block
markdownListToEditorBlock lb children =
    let
        ( node, typeAttributes ) =
            case lb.type_ of
                Block.Ordered i ->
                    ( Definitions.orderedList, [ Attribute.IntegerAttribute "startIndex" i ] )

                Block.Unordered ->
                    ( Definitions.unorderedList, [] )

        attributes =
            [ Attribute.IntegerAttribute "indentLength" lb.indentLength
            , Attribute.StringAttribute "delimiter" lb.delimiter
            ]
                ++ typeAttributes
    in
    Result.map
        (\listItems ->
            ModelNode.block
                (Element.element node attributes)
                (ModelNode.blockChildren
                    (Array.fromList
                        (List.map
                            (\cn ->
                                ModelNode.block
                                    (Element.element Definitions.listItem [])
                                    cn
                            )
                            listItems
                        )
                    )
                )
        )
        (unwrapAndFilterChildNodes
            (List.map
                (\x -> markdownBlockListToBlockChildNodes x)
                children
            )
        )


markdownInlineToParagraphBlock : List MInline -> Result String Block
markdownInlineToParagraphBlock children =
    Result.map
        (\c ->
            ModelNode.block
                (Element.element Definitions.paragraph [])
                c
        )
        (markdownInlineListToInlineChildNodes children)


markdownBlockToEditorBlock : MBlock -> Result String Block
markdownBlockToEditorBlock mblock =
    case mblock of
        Block.BlankLine s ->
            Ok <|
                ModelNode.block
                    (Element.element Definitions.paragraph [])
                    (ModelNode.inlineChildren <| Array.fromList [ ModelNode.plainText s ])

        Block.ThematicBreak ->
            Ok <|
                ModelNode.block
                    (Element.element Definitions.horizontalRule [])
                    ModelNode.Leaf

        Block.Heading _ i children ->
            Result.map
                (\c ->
                    ModelNode.block
                        (Element.element
                            Definitions.heading
                            [ Attribute.IntegerAttribute "level" i ]
                        )
                        c
                )
                (markdownInlineListToInlineChildNodes children)

        Block.CodeBlock cb s ->
            markdownCodeBlockToEditorBlock cb s

        Block.Paragraph _ children ->
            markdownInlineToParagraphBlock children

        Block.BlockQuote children ->
            Result.map
                (\c ->
                    ModelNode.block
                        (Element.element Definitions.blockquote [])
                        c
                )
                (markdownBlockListToBlockChildNodes children)

        Block.List lb listItems ->
            markdownListToEditorBlock lb listItems

        Block.PlainInlines children ->
            markdownInlineToParagraphBlock children

        Block.Custom _ _ ->
            Err "Custom elements are not implemented"


filterBlankLines : List MBlock -> List MBlock
filterBlankLines blocks =
    let
        newBlocks =
            List.filterMap
                (\block ->
                    case block of
                        Block.BlankLine _ ->
                            Nothing

                        Block.BlockQuote children ->
                            Just <| Block.BlockQuote (filterBlankLines children)

                        Block.List lb listItems ->
                            Just <| Block.List lb (List.map filterBlankLines listItems)

                        _ ->
                            Just block
                )
                blocks
    in
    if List.isEmpty newBlocks then
        [ Block.BlankLine "" ]

    else
        newBlocks
