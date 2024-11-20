module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Review.Rule exposing (Rule)


import EnforceBoundaries exposing (Layer(..), Stack(..))
import NoExposingEverything
import NoImportingEverything
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
     -- NoUnused.Exports.rule
      NoUnused.Modules.rule

    --, NoUnused.Parameters.rule -- Needs manual clean up.
    --, NoUnused.Variables.rule
    , NoUnused.Patterns.rule
    , NoExposingEverything.rule

    , NoMissingTypeExpose.rule -- Mostly useful for packages not applications.
    , NoMissingTypeAnnotation.rule -- Aspirational, should try and get this back in.
    , NoImportingEverything.rule []
    , NoSimpleLetBody.rule
    --, EnforceBoundaries.rule moduleLayerRule
    ]
