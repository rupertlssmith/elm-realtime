module AITrace.Style exposing (style)

import Css
import Css.Global


style : List Css.Global.Snippet
style =
    [ Css.Global.class "aitrace-frame"
        []
    , Css.Global.class "aitrace-log-container"
        [ Css.pct 100 |> Css.width
        , Css.pct 100 |> Css.height
        , Css.backgroundColor (Css.rgb 255 255 255)
        , Css.overflowY Css.auto
        ]
    , Css.Global.class "aitrace-log"
        [ Css.px 8 |> Css.padding
        , Css.px 4 |> Css.margin
        , Css.displayFlex
        , Css.flexDirection Css.row
        , Css.justifyContent Css.spaceAround
        , Css.alignItems Css.flexStart
        ]
    , Css.Global.class "aitrace-text"
        []
    ]
