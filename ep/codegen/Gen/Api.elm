module Gen.Api exposing (call_, moduleName_, routes, values_)

{-| 
@docs moduleName_, routes, call_, values_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Api" ]


{-| routes: 
    BackendTask.BackendTask FatalError.FatalError (List Route.Route)
    -> (Maybe { indent : Int, newLines : Bool } -> Html.Html Basics.Never -> String)
    -> List (ApiRoute.ApiRoute ApiRoute.Response)
-}
routes :
    Elm.Expression
    -> (Elm.Expression -> Elm.Expression -> Elm.Expression)
    -> Elm.Expression
routes routesArg routesArg0 =
    Elm.apply
        (Elm.value
             { importFrom = [ "Api" ]
             , name = "routes"
             , annotation =
                 Just
                     (Type.function
                          [ Type.namedWith
                              [ "BackendTask" ]
                              "BackendTask"
                              [ Type.namedWith [ "FatalError" ] "FatalError" []
                              , Type.list
                                    (Type.namedWith [ "Route" ] "Route" [])
                              ]
                          , Type.function
                              [ Type.maybe
                                    (Type.record
                                         [ ( "indent", Type.int )
                                         , ( "newLines", Type.bool )
                                         ]
                                    )
                              , Type.namedWith
                                    [ "Html" ]
                                    "Html"
                                    [ Type.namedWith [ "Basics" ] "Never" [] ]
                              ]
                              Type.string
                          ]
                          (Type.list
                               (Type.namedWith
                                    [ "ApiRoute" ]
                                    "ApiRoute"
                                    [ Type.namedWith
                                        [ "ApiRoute" ]
                                        "Response"
                                        []
                                    ]
                               )
                          )
                     )
             }
        )
        [ routesArg
        , Elm.functionReduced
            "routesUnpack"
            (\functionReducedUnpack ->
               Elm.functionReduced "unpack" (routesArg0 functionReducedUnpack)
            )
        ]


call_ : { routes : Elm.Expression -> Elm.Expression -> Elm.Expression }
call_ =
    { routes =
        \routesArg routesArg0 ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "Api" ]
                     , name = "routes"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.namedWith
                                      [ "BackendTask" ]
                                      "BackendTask"
                                      [ Type.namedWith
                                            [ "FatalError" ]
                                            "FatalError"
                                            []
                                      , Type.list
                                            (Type.namedWith
                                                 [ "Route" ]
                                                 "Route"
                                                 []
                                            )
                                      ]
                                  , Type.function
                                      [ Type.maybe
                                            (Type.record
                                                 [ ( "indent", Type.int )
                                                 , ( "newLines", Type.bool )
                                                 ]
                                            )
                                      , Type.namedWith
                                            [ "Html" ]
                                            "Html"
                                            [ Type.namedWith
                                                [ "Basics" ]
                                                "Never"
                                                []
                                            ]
                                      ]
                                      Type.string
                                  ]
                                  (Type.list
                                       (Type.namedWith
                                            [ "ApiRoute" ]
                                            "ApiRoute"
                                            [ Type.namedWith
                                                [ "ApiRoute" ]
                                                "Response"
                                                []
                                            ]
                                       )
                                  )
                             )
                     }
                )
                [ routesArg, routesArg0 ]
    }


values_ : { routes : Elm.Expression }
values_ =
    { routes =
        Elm.value
            { importFrom = [ "Api" ]
            , name = "routes"
            , annotation =
                Just
                    (Type.function
                         [ Type.namedWith
                             [ "BackendTask" ]
                             "BackendTask"
                             [ Type.namedWith [ "FatalError" ] "FatalError" []
                             , Type.list (Type.namedWith [ "Route" ] "Route" [])
                             ]
                         , Type.function
                             [ Type.maybe
                                   (Type.record
                                        [ ( "indent", Type.int )
                                        , ( "newLines", Type.bool )
                                        ]
                                   )
                             , Type.namedWith
                                   [ "Html" ]
                                   "Html"
                                   [ Type.namedWith [ "Basics" ] "Never" [] ]
                             ]
                             Type.string
                         ]
                         (Type.list
                              (Type.namedWith
                                   [ "ApiRoute" ]
                                   "ApiRoute"
                                   [ Type.namedWith [ "ApiRoute" ] "Response" []
                                   ]
                              )
                         )
                    )
            }
    }