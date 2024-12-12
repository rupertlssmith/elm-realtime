module Top.Style exposing (rawCssStyle, style)

import Css exposing (Color)
import Css.Global
import Html.Styled as HS exposing (Html)


printBlack : Color
printBlack =
    Css.rgb 25 25 25


type alias Config a =
    { a
        | leftMenuWidth : Float
        , rightOverlayWidth : Float
    }


rawCssStyle : Html msg
rawCssStyle =
    HS.node "style" [] [ HS.text rawCss ]


rawCss : String
rawCss =
    "@import url('https://fonts.googleapis.com/css?family=Open+Sans:400,400i,600,700,700i');"


style : Config a -> List Css.Global.Snippet
style config =
    [ Css.Global.html
        [ Css.pct 100 |> Css.height ]
    , Css.Global.body
        [ Css.pct 100 |> Css.height
        , Css.overflow Css.hidden
        , Css.touchAction Css.none
        , Css.px 16 |> Css.fontSize
        , Css.fontFamilies [ "Open Sans", "sans-serif" ]

        -- Required for Chrome or you get pointercancel when drags start and end on different divs.
        --, Css.property "user-select" "none"
        , Css.property "-webkit-font-smoothing" "antialiased"
        ]
    , Css.Global.id "top-container"
        [ Css.pct 100 |> Css.width
        , Css.pct 100 |> Css.height
        , Css.overflow Css.hidden
        , Css.displayFlex
        , Css.flexDirection Css.row
        , Css.justifyContent Css.flexStart
        , Css.alignItems Css.stretch
        ]
    , Css.Global.id "left-menu"
        [ printBlack |> Css.backgroundColor
        , Css.px config.leftMenuWidth |> Css.width
        ]
    , Css.Global.id "right-overlay"
        [ Css.position Css.fixed
        , Css.px 0 |> Css.top
        , Css.px 0 |> Css.right
        , Css.px config.rightOverlayWidth |> Css.minWidth
        , Css.px config.rightOverlayWidth |> Css.maxWidth
        , Css.vh 100 |> Css.height
        , Css.rgba 125 125 125 0.7 |> Css.backgroundColor
        ]
    , Css.Global.selector "h3"
        [ Css.px 6 |> Css.marginTop
        , Css.px 10 |> Css.marginBottom
        ]
    , Css.Global.class "log"
        [ Css.overflow Css.auto
        , Css.pct 100 |> Css.width
        ]
    , Css.Global.class "noselect"
        [ Css.property "user-select" "none"
        , Css.property "-moz-user-select" "none"
        , Css.property "-webkit-user-select" "none"
        , Css.property "-ms-user-select" "none"
        ]
    , Css.Global.selector "::selection"
        [ Css.backgroundColor (Css.rgb 196 195 217)
        ]
    ]
