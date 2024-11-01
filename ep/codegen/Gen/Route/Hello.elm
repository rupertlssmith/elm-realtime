module Gen.Route.Hello exposing (action, annotation_, call_, caseOf_, data, make_, moduleName_, values_)

{-| 
@docs moduleName_, action, data, annotation_, make_, caseOf_, call_, values_
-}


import Elm
import Elm.Annotation as Type
import Elm.Case


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Route", "Hello" ]


{-| action: 
    Route.Hello.RouteParams
    -> Server.Request.Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response Route.Hello.ActionData ErrorPage.ErrorPage)
-}
action : Elm.Expression -> Elm.Expression -> Elm.Expression
action actionArg actionArg0 =
    Elm.apply
        (Elm.value
             { importFrom = [ "Route", "Hello" ]
             , name = "action"
             , annotation =
                 Just
                     (Type.function
                          [ Type.namedWith [ "Route", "Hello" ] "RouteParams" []
                          , Type.namedWith [ "Server", "Request" ] "Request" []
                          ]
                          (Type.namedWith
                               [ "BackendTask" ]
                               "BackendTask"
                               [ Type.namedWith [ "FatalError" ] "FatalError" []
                               , Type.namedWith
                                   [ "Server", "Response" ]
                                   "Response"
                                   [ Type.namedWith
                                         [ "Route", "Hello" ]
                                         "ActionData"
                                         []
                                   , Type.namedWith
                                         [ "ErrorPage" ]
                                         "ErrorPage"
                                         []
                                   ]
                               ]
                          )
                     )
             }
        )
        [ actionArg, actionArg0 ]


{-| data: 
    Route.Hello.RouteParams
    -> Server.Request.Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response Route.Hello.Data ErrorPage.ErrorPage)
-}
data : Elm.Expression -> Elm.Expression -> Elm.Expression
data dataArg dataArg0 =
    Elm.apply
        (Elm.value
             { importFrom = [ "Route", "Hello" ]
             , name = "data"
             , annotation =
                 Just
                     (Type.function
                          [ Type.namedWith [ "Route", "Hello" ] "RouteParams" []
                          , Type.namedWith [ "Server", "Request" ] "Request" []
                          ]
                          (Type.namedWith
                               [ "BackendTask" ]
                               "BackendTask"
                               [ Type.namedWith [ "FatalError" ] "FatalError" []
                               , Type.namedWith
                                   [ "Server", "Response" ]
                                   "Response"
                                   [ Type.namedWith
                                         [ "Route", "Hello" ]
                                         "Data"
                                         []
                                   , Type.namedWith
                                         [ "ErrorPage" ]
                                         "ErrorPage"
                                         []
                                   ]
                               ]
                          )
                     )
             }
        )
        [ dataArg, dataArg0 ]


annotation_ :
    { actionData : Type.Annotation
    , data : Type.Annotation
    , routeParams : Type.Annotation
    , model : Type.Annotation
    , msg : Type.Annotation
    }
annotation_ =
    { actionData = Type.alias moduleName_ "ActionData" [] (Type.record [])
    , data =
        Type.alias moduleName_ "Data" [] (Type.record [ ( "stars", Type.int ) ])
    , routeParams = Type.alias moduleName_ "RouteParams" [] (Type.record [])
    , model = Type.alias moduleName_ "Model" [] (Type.record [])
    , msg = Type.namedWith [ "Route", "Hello" ] "Msg" []
    }


make_ :
    { actionData : actionData -> Elm.Expression
    , data : { stars : Elm.Expression } -> Elm.Expression
    , routeParams : routeParams -> Elm.Expression
    , model : model -> Elm.Expression
    , noOp : Elm.Expression
    }
make_ =
    { actionData =
        \actionData_args ->
            Elm.withType
                (Type.alias
                     [ "Route", "Hello" ]
                     "ActionData"
                     []
                     (Type.record [])
                )
                (Elm.record [])
    , data =
        \data_args ->
            Elm.withType
                (Type.alias
                     [ "Route", "Hello" ]
                     "Data"
                     []
                     (Type.record [ ( "stars", Type.int ) ])
                )
                (Elm.record [ Tuple.pair "stars" data_args.stars ])
    , routeParams =
        \routeParams_args ->
            Elm.withType
                (Type.alias
                     [ "Route", "Hello" ]
                     "RouteParams"
                     []
                     (Type.record [])
                )
                (Elm.record [])
    , model =
        \model_args ->
            Elm.withType
                (Type.alias [ "Route", "Hello" ] "Model" [] (Type.record []))
                (Elm.record [])
    , noOp =
        Elm.value
            { importFrom = [ "Route", "Hello" ]
            , name = "NoOp"
            , annotation = Just (Type.namedWith [] "Msg" [])
            }
    }


caseOf_ :
    { msg :
        Elm.Expression
        -> { msgTags_0_0 | noOp : Elm.Expression }
        -> Elm.Expression
    }
caseOf_ =
    { msg =
        \msgExpression msgTags ->
            Elm.Case.custom
                msgExpression
                (Type.namedWith [ "Route", "Hello" ] "Msg" [])
                [ Elm.Case.branch0 "NoOp" msgTags.noOp ]
    }


call_ :
    { action : Elm.Expression -> Elm.Expression -> Elm.Expression
    , data : Elm.Expression -> Elm.Expression -> Elm.Expression
    }
call_ =
    { action =
        \actionArg actionArg0 ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "Route", "Hello" ]
                     , name = "action"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.namedWith
                                      [ "Route", "Hello" ]
                                      "RouteParams"
                                      []
                                  , Type.namedWith
                                      [ "Server", "Request" ]
                                      "Request"
                                      []
                                  ]
                                  (Type.namedWith
                                       [ "BackendTask" ]
                                       "BackendTask"
                                       [ Type.namedWith
                                           [ "FatalError" ]
                                           "FatalError"
                                           []
                                       , Type.namedWith
                                           [ "Server", "Response" ]
                                           "Response"
                                           [ Type.namedWith
                                                 [ "Route", "Hello" ]
                                                 "ActionData"
                                                 []
                                           , Type.namedWith
                                                 [ "ErrorPage" ]
                                                 "ErrorPage"
                                                 []
                                           ]
                                       ]
                                  )
                             )
                     }
                )
                [ actionArg, actionArg0 ]
    , data =
        \dataArg dataArg0 ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "Route", "Hello" ]
                     , name = "data"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.namedWith
                                      [ "Route", "Hello" ]
                                      "RouteParams"
                                      []
                                  , Type.namedWith
                                      [ "Server", "Request" ]
                                      "Request"
                                      []
                                  ]
                                  (Type.namedWith
                                       [ "BackendTask" ]
                                       "BackendTask"
                                       [ Type.namedWith
                                           [ "FatalError" ]
                                           "FatalError"
                                           []
                                       , Type.namedWith
                                           [ "Server", "Response" ]
                                           "Response"
                                           [ Type.namedWith
                                                 [ "Route", "Hello" ]
                                                 "Data"
                                                 []
                                           , Type.namedWith
                                                 [ "ErrorPage" ]
                                                 "ErrorPage"
                                                 []
                                           ]
                                       ]
                                  )
                             )
                     }
                )
                [ dataArg, dataArg0 ]
    }


values_ : { action : Elm.Expression, data : Elm.Expression }
values_ =
    { action =
        Elm.value
            { importFrom = [ "Route", "Hello" ]
            , name = "action"
            , annotation =
                Just
                    (Type.function
                         [ Type.namedWith [ "Route", "Hello" ] "RouteParams" []
                         , Type.namedWith [ "Server", "Request" ] "Request" []
                         ]
                         (Type.namedWith
                              [ "BackendTask" ]
                              "BackendTask"
                              [ Type.namedWith [ "FatalError" ] "FatalError" []
                              , Type.namedWith
                                  [ "Server", "Response" ]
                                  "Response"
                                  [ Type.namedWith
                                        [ "Route", "Hello" ]
                                        "ActionData"
                                        []
                                  , Type.namedWith
                                        [ "ErrorPage" ]
                                        "ErrorPage"
                                        []
                                  ]
                              ]
                         )
                    )
            }
    , data =
        Elm.value
            { importFrom = [ "Route", "Hello" ]
            , name = "data"
            , annotation =
                Just
                    (Type.function
                         [ Type.namedWith [ "Route", "Hello" ] "RouteParams" []
                         , Type.namedWith [ "Server", "Request" ] "Request" []
                         ]
                         (Type.namedWith
                              [ "BackendTask" ]
                              "BackendTask"
                              [ Type.namedWith [ "FatalError" ] "FatalError" []
                              , Type.namedWith
                                  [ "Server", "Response" ]
                                  "Response"
                                  [ Type.namedWith
                                        [ "Route", "Hello" ]
                                        "Data"
                                        []
                                  , Type.namedWith
                                        [ "ErrorPage" ]
                                        "ErrorPage"
                                        []
                                  ]
                              ]
                         )
                    )
            }
    }