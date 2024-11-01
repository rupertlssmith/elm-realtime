module Gen.Site exposing (config, moduleName_, values_)

{-| 
@docs moduleName_, config, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Site" ]


{-| config: SiteConfig.SiteConfig -}
config : Elm.Expression
config =
    Elm.value
        { importFrom = [ "Site" ]
        , name = "config"
        , annotation = Just (Type.namedWith [ "SiteConfig" ] "SiteConfig" [])
        }


values_ : { config : Elm.Expression }
values_ =
    { config =
        Elm.value
            { importFrom = [ "Site" ]
            , name = "config"
            , annotation =
                Just (Type.namedWith [ "SiteConfig" ] "SiteConfig" [])
            }
    }