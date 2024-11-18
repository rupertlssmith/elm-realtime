module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import NoExposingEverything
import NoImportingEverything
import NoInconsistentAliases
import NoMissingTypeAnnotation
import NoMissingTypeExpose
import NoSimpleLetBody
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule exposing (Rule)


config : List Rule
config =
    [ --NoUnused.Dependencies.rule
      NoUnused.Exports.rule
    , NoUnused.Modules.rule

    --, NoUnused.Parameters.rule -- Needs manual clean up.
    --, NoUnused.Variables.rule
    , NoUnused.Patterns.rule
    , NoExposingEverything.rule
    , NoMissingTypeAnnotation.rule
    , NoSimpleLetBody.rule
    , NoInconsistentAliases.config
        [ ( "Html.Attributes", "HA" )
        , ( "Html.Events", "HE" )
        , ( "Json.Decode", "Decode" )
        , ( "Json.Encode", "Encode" )
        , ( "Update2", "U2" )
        , ( "Html.Styled", "HS" )
        , ( "Html.Styled.Attributes", "HA" )
        , ( "Html.Styled.Events", "HE" )
        , ( "TypedSvg", "Svg" )
        , ( "TypedSvg.Attributes", "SvgAttr" )
        , ( "TypedSvg.Core", "SvgCore" )
        ]
        |> NoInconsistentAliases.noMissingAliases
        |> NoInconsistentAliases.rule
    ]
