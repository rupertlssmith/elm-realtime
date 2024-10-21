module Icon exposing (caretRightFill, caretUpFill, closex, robot, user)

import Svg exposing (..)
import Svg.Attributes as SA exposing (..)


caretUpFill : Svg msg
caretUpFill =
    svg [ width "100%", height "100%", fill "currentColor", class "bi bi-robot", viewBox "0 0 16 16" ]
        [ Svg.path [ d "m7.247 4.86-4.796 5.481c-.566.647-.106 1.659.753 1.659h9.592a1 1 0 0 0 .753-1.659l-4.796-5.48a1 1 0 0 0-1.506 0z" ]
            []
        ]


caretRightFill : Svg msg
caretRightFill =
    svg [ width "16", height "16", fill "currentColor", class "bi bi-caret-right-fill", viewBox "0 0 16 16" ]
        [ Svg.path [ d "m12.14 8.753-5.482 4.796c-.646.566-1.658.106-1.658-.753V3.204a1 1 0 0 1 1.659-.753l5.48 4.796a1 1 0 0 1 0 1.506z" ] []
        ]


closex : Svg msg
closex =
    svg [ width "100%", height "100%", fill "currentColor", class "bi bi-robot", viewBox "0 0 16 16" ]
        [ Svg.path [ d "M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z" ]
            []
        ]


user : Svg msg
user =
    svg [ width "16", height "16", fill "currentColor", class "bi bi-person-circle", viewBox "0 0 16 16" ]
        [ Svg.path [ d "M11 6a3 3 0 1 1-6 0 3 3 0 0 1 6 0" ]
            []
        , Svg.path [ fillRule "evenodd", d "M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8m8-7a7 7 0 0 0-5.468 11.37C3.242 11.226 4.805 10 8 10s4.757 1.225 5.468 2.37A7 7 0 0 0 8 1" ]
            []
        ]


robot : Svg msg
robot =
    svg [ width "100%", height "100%", fill "currentColor", class "bi bi-robot", viewBox "0 0 16 16" ]
        [ Svg.defs []
            [ Svg.linearGradient
                [ id "linearGradient3104"
                , x1 "25.092787"
                , y1 "7.2023954"
                , x2 "33.743694"
                , y2 "2.8182027"
                , gradientUnits "userSpaceOnUse"
                , gradientTransform "translate(-19.764964,2.6877393)"
                ]
                [ stop
                    [ SA.style "stop-color:#2880a4;stop-opacity:1"
                    , offset "0"
                    ]
                    []
                , stop
                    [ SA.style "stop-color:#80e2b5;stop-opacity:0.99607843"
                    , offset "1"
                    ]
                    []
                ]
            ]
        , Svg.path
            [ d "M8.5 1.866a1 1 0 1 0-1 0V3h-2A4.5 4.5 0 0 0 1 7.5V8a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1v1a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-1a1 1 0 0 0 1-1V9a1 1 0 0 0-1-1v-.5A4.5 4.5 0 0 0 10.5 3h-2V1.866ZM14 7.5V13a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V7.5A3.5 3.5 0 0 1 5.5 4h5A3.5 3.5 0 0 1 14 7.5Z" ]
            []
        , Svg.path
            [ d "M 6,12.5 A 0.5,0.5 0 0 1 6.5,12 h 3 a 0.5,0.5 0 0 1 0,1 h -3 A 0.5,0.5 0 0 1 6,12.5 Z" ]
            []
        , Svg.path
            [ d "M 3,8.062 C 3,6.76 4.235,5.765 5.53,5.886 a 26.58,26.58 0 0 0 4.94,0 C 11.765,5.765 13,6.76 13,8.062 v 1.157 a 0.933,0.933 0 0 1 -0.765,0.935 C 11.39,10.301 9.895,10.5 8,10.5 6.105,10.5 4.61,10.3 3.765,10.154 A 0.933,0.933 0 0 1 3,9.219 Z M 7.542,7.235 A 0.25,0.25 0 0 0 7.325,7.303 l -0.92,0.9 A 24.767,24.767 0 0 1 4.534,8.02 0.25,0.25 0 0 0 4.466,8.515 c 0.55,0.076 1.232,0.149 2.02,0.193 A 0.25,0.25 0 0 0 6.675,8.637 L 7.429,7.901 8.276,9.611 A 0.25,0.25 0 0 0 8.68,9.673 L 9.612,8.703 A 25.286,25.286 0 0 0 11.534,8.515 0.25,0.25 0 0 0 11.466,8.02 C 10.928,8.094 10.259,8.165 9.486,8.209 A 0.25,0.25 0 0 0 9.32,8.285 L 8.566,9.07 7.724,7.37 A 0.25,0.25 0 0 0 7.542,7.235 Z"
            , fill "url(#linearGradient3104)"
            ]
            []
        ]
