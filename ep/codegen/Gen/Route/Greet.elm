module Gen.Route.Greet exposing (annotation_, make_, moduleName_, route, values_)

{-| 
@docs moduleName_, route, annotation_, make_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "Greet" ]


{-| route: RouteBuilder.StatelessRoute Route.Greet.RouteParams Route.Greet.Data Route.Greet.ActionData -}
route : Elm.Expression
route =
    Elm.value
        { importFrom = [ "Route", "Greet" ]
        , name = "route"
        , annotation =
            Just
                (Type.namedWith
                     [ "RouteBuilder" ]
                     "StatelessRoute"
                     [ Type.namedWith [ "Route", "Greet" ] "RouteParams" []
                     , Type.namedWith [ "Route", "Greet" ] "Data" []
                     , Type.namedWith [ "Route", "Greet" ] "ActionData" []
                     ]
                )
        }


annotation_ :
    { actionData : Type.Annotation
    , data : Type.Annotation
    , msg : Type.Annotation
    , model : Type.Annotation
    }
annotation_ =
    { actionData = Type.alias moduleName_ "ActionData" [] (Type.record [])
    , data =
        Type.alias
            moduleName_
            "Data"
            []
            (Type.record [ ( "name", Type.maybe Type.string ) ])
    , msg = Type.alias moduleName_ "Msg" [] Type.unit
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
    }


make_ :
    { actionData : actionData -> Elm.Expression
    , data : { name : Elm.Expression } -> Elm.Expression
    , model : model -> Elm.Expression
    }
make_ =
    { actionData =
        \actionData_args ->
            Elm.withType
                (Type.alias
                     [ "Route", "Greet" ]
                     "ActionData"
                     []
                     (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias
                     [ "Route", "Greet" ]
                     "Data"
                     []
                     (Type.record [ ( "name", Type.maybe Type.string ) ])
                )
                (Elm.record [ Tuple.pair "name" data_args.name ])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias [ "Route", "Greet" ] "Model" [] (Type.record []))
                (Elm.record [])
    }


values_ : { route : Elm.Expression }
values_ =
    { route =
        Elm.value
            { importFrom = [ "Route", "Greet" ]
            , name = "route"
            , annotation =
                Just
                    (Type.namedWith
                         [ "RouteBuilder" ]
                         "StatelessRoute"
                         [ Type.namedWith [ "Route", "Greet" ] "RouteParams" []
                         , Type.namedWith [ "Route", "Greet" ] "Data" []
                         , Type.namedWith [ "Route", "Greet" ] "ActionData" []
                         ]
                    )
            }
    }