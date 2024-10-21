module IntelligentAgent.Style exposing (style)

import Css
import Css.Global


style : List Css.Global.Snippet
style =
    [ Css.Global.class "ia-frame"
        [ Css.position Css.fixed
        , Css.int 1900 |> Css.zIndex
        ]
    , Css.Global.class "ia-chat-container"
        [ Css.position Css.absolute
        , Css.px 120 |> Css.left
        , Css.px 150 |> Css.top
        , Css.px 500 |> Css.maxHeight
        , Css.backgroundColor (Css.rgb 255 255 255)
        , Css.boxShadow4 (Css.px 3) (Css.px 3) (Css.px 3) (Css.rgb 140 140 140)
        , Css.overflowY Css.hidden
        ]
    , Css.Global.class "ia-chat-scroll"
        [ Css.overflowY Css.auto
        , Css.px 476 |> Css.maxHeight
        ]
    , Css.Global.class "ia-chat"
        [ Css.position Css.relative
        , Css.backgroundColor (Css.rgb 240 240 250)
        , Css.px 8 |> Css.padding
        , Css.px 4 |> Css.margin
        , Css.border3 (Css.px 0.5) Css.solid (Css.rgb 230 230 240)
        , Css.px 2 |> Css.borderRadius
        , Css.px 440 |> Css.width
        , Css.displayFlex
        , Css.flexDirection Css.row
        , Css.justifyContent Css.spaceAround
        , Css.alignItems Css.flexStart
        ]
    , Css.Global.class "ia-chat-icon"
        [ Css.px 20 |> Css.width
        , Css.px 20 |> Css.height
        ]
    , Css.Global.class "ia-chat-text"
        [ Css.px 400 |> Css.width
        , Css.flexBasis Css.auto
        ]
    , Css.Global.class "ia-chat-text-title"
        [ Css.padding (0.2 |> Css.em)
        , Css.margin (0.2 |> Css.em)
        ]
    , Css.Global.class "ia-chat-text-body"
        [ Css.padding2 (0.2 |> Css.em) (0.2 |> Css.em)
        , Css.Global.children
            [ Css.Global.typeSelector "p"
                [ Css.em 0.2 |> Css.marginBlockStart
                , Css.em 0.5 |> Css.marginBlockEnd
                ]
            ]
        , Css.property "user-select" "text"
        ]
    , Css.Global.class "ia-chat-text-children"
        [ Css.padding2 (0.2 |> Css.em) (0.4 |> Css.em)
        ]
    , Css.Global.class "ia-chat-text-child"
        [ Css.hover [ Css.backgroundColor (Css.rgba 0 0 0 0.1) ]
        , Css.cursor Css.pointer
        , Css.padding2 (0.2 |> Css.em) (0.0 |> Css.em)
        , Css.property "user-select" "none"
        ]
    , Css.Global.class "ia-chat-text-child-icon"
        [ Css.display Css.inline
        , Css.px 20 |> Css.width
        , Css.px 20 |> Css.height
        ]
    , Css.Global.class "ia-chat-topbar"
        [ Css.displayFlex
        , Css.flexDirection Css.row
        , Css.justifyContent Css.flexEnd
        , Css.px 24 |> Css.height
        , Css.margin2 (0 |> Css.em) (0.2 |> Css.em)
        , Css.backgroundColor (Css.rgb 230 230 240)
        ]
    , Css.Global.selector "elm-editor"
        [ Css.pct 100 |> Css.width
        ]
    , Css.Global.class "rte-main"
        [ Css.pct 100 |> Css.width
        ]
    , Css.Global.class "ia-chat-toolbar"
        [ Css.displayFlex
        , Css.flexDirection Css.row
        , Css.backgroundColor (Css.rgb 255 255 255)
        ]
    , Css.Global.class "content-main"
        [ Css.outline3 (Css.px 0) Css.solid Css.transparent
        , Css.property "user-select" "text"
        , Css.property "-moz-user-select" "text"
        , Css.property "-webkit-user-select" "text"
        , Css.property "-ms-user-select" "text"
        , Css.backgroundColor (Css.rgb 230 230 150)
        , Css.pct 100 |> Css.width
        ]
    , Css.Global.class "ia-chat-user-input"
        [ Css.displayFlex
        , Css.outline Css.none
        , Css.Global.descendants
            [ Css.Global.typeSelector "div"
                []
            , Css.Global.typeSelector "p"
                [ Css.em 0.2 |> Css.marginBlockStart
                , Css.em 0.5 |> Css.marginBlockEnd
                ]
            ]
        ]
    , Css.Global.class "rte-hide-caret"
        [ Css.property "caretColor" "transparent"
        ]

    -- Inline essence Element.
    , Css.Global.class "essence-element"
        [ Css.display Css.inlineBlock
        , Css.verticalAlign Css.middle
        , Css.Global.children
            [ Css.Global.typeSelector "a"
                [ Css.displayFlex
                , Css.alignSelf Css.flexStart
                , Css.flex3 (0 |> Css.int) (1 |> Css.int) (50 |> Css.pct)
                , Css.flexDirection Css.row
                , Css.color Css.inherit
                , Css.textDecoration Css.inherit
                , Css.padding2 (0.2 |> Css.em) (0.2 |> Css.em)

                --, Css.alignItems Css.center
                , Css.hover [ Css.backgroundColor (Css.rgba 0 0 0 0.1) ]

                -- Is there a better "type-safe" way of specifying properties such as `user-select`?
                , Css.property "user-select" "none"
                , Css.Global.children
                    [ -- First `div` in an Essence Element is its icon.
                      Css.Global.typeSelector "div"
                        [ Css.display Css.inline
                        , Css.width (1.4 |> Css.em)
                        , Css.height (1.2 |> Css.em)
                        , Css.flexShrink (0 |> Css.int)
                        ]
                    , -- H5 in an Essence Element is its text.
                      Css.Global.typeSelector "h5"
                        [ Css.display Css.inlineBlock
                        , Css.margin (0 |> Css.px)
                        , Css.paddingLeft (0.2 |> Css.em)

                        --, Css.fontSize (0.8 |> Css.em)
                        , Css.fontWeight Css.normal
                        ]
                    ]
                ]
            ]
        ]
    ]
