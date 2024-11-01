module Gen.Pages exposing (builtAt, moduleName_, values_)

{-| 
@docs moduleName_, builtAt, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Pages" ]


{-| builtAt: Time.Posix -}
builtAt : Elm.Expression
builtAt =
    Elm.value
        { importFrom = [ "Pages" ]
        , name = "builtAt"
        , annotation = Just (Type.namedWith [ "Time" ] "Posix" [])
        }


values_ : { builtAt : Elm.Expression }
values_ =
    { builtAt =
        Elm.value
            { importFrom = [ "Pages" ]
            , name = "builtAt"
            , annotation = Just (Type.namedWith [ "Time" ] "Posix" [])
            }
    }