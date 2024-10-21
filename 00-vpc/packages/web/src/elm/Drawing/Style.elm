module Drawing.Style exposing (offWhite, style)

import Color exposing (Color)
import Css
import Css.Global


offWhite : Color
offWhite =
    Color.rgb255 248 246 251


style : List Css.Global.Snippet
style =
    [ Css.Global.id "drawing-container"
        [ Css.pct 100 |> Css.width
        , Css.pct 100 |> Css.height
        ]
    , Css.Global.id "svg-drawing"
        []
    ]
