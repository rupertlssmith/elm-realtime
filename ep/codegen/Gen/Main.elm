module Gen.Main exposing (main, moduleName_, values_)

{-| 
@docs moduleName_, main, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Main" ]


{-| main: Platform.Program Pages.Internal.Platform.Flags (Pages.Internal.Platform.Model Main.Model Main.PageData Main.ActionData Shared.Data) (Pages.Internal.Platform.Msg Main.Msg Main.PageData Main.ActionData Shared.Data ErrorPage.ErrorPage) -}
main : Elm.Expression
main =
    Elm.value
        { importFrom = [ "Main" ]
        , name = "main"
        , annotation =
            Just
                (Type.namedWith
                     [ "Platform" ]
                     "Program"
                     [ Type.namedWith
                         [ "Pages", "Internal", "Platform" ]
                         "Flags"
                         []
                     , Type.namedWith
                         [ "Pages", "Internal", "Platform" ]
                         "Model"
                         [ Type.namedWith [ "Main" ] "Model" []
                         , Type.namedWith [ "Main" ] "PageData" []
                         , Type.namedWith [ "Main" ] "ActionData" []
                         , Type.namedWith [ "Shared" ] "Data" []
                         ]
                     , Type.namedWith
                         [ "Pages", "Internal", "Platform" ]
                         "Msg"
                         [ Type.namedWith [ "Main" ] "Msg" []
                         , Type.namedWith [ "Main" ] "PageData" []
                         , Type.namedWith [ "Main" ] "ActionData" []
                         , Type.namedWith [ "Shared" ] "Data" []
                         , Type.namedWith [ "ErrorPage" ] "ErrorPage" []
                         ]
                     ]
                )
        }


values_ : { main_ : Elm.Expression }
values_ =
    { main_ =
        Elm.value
            { importFrom = [ "Main" ]
            , name = "main"
            , annotation =
                Just
                    (Type.namedWith
                         [ "Platform" ]
                         "Program"
                         [ Type.namedWith
                             [ "Pages", "Internal", "Platform" ]
                             "Flags"
                             []
                         , Type.namedWith
                             [ "Pages", "Internal", "Platform" ]
                             "Model"
                             [ Type.namedWith [ "Main" ] "Model" []
                             , Type.namedWith [ "Main" ] "PageData" []
                             , Type.namedWith [ "Main" ] "ActionData" []
                             , Type.namedWith [ "Shared" ] "Data" []
                             ]
                         , Type.namedWith
                             [ "Pages", "Internal", "Platform" ]
                             "Msg"
                             [ Type.namedWith [ "Main" ] "Msg" []
                             , Type.namedWith [ "Main" ] "PageData" []
                             , Type.namedWith [ "Main" ] "ActionData" []
                             , Type.namedWith [ "Shared" ] "Data" []
                             , Type.namedWith [ "ErrorPage" ] "ErrorPage" []
                             ]
                         ]
                    )
            }
    }