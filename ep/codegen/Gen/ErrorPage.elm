module Gen.ErrorPage exposing (annotation_, call_, caseOf_, head, init, internalError, make_, moduleName_, notFound, statusCode, update, values_, view)

{-| 
@docs moduleName_, statusCode, view, internalError, notFound, head, update, init, annotation_, make_, caseOf_, call_, values_
-}


import Elm
import Elm.Annotation as Type
import Elm.Case


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "ErrorPage" ]


{-| statusCode: ErrorPage.ErrorPage -> number -}
statusCode : Elm.Expression -> Elm.Expression
statusCode statusCodeArg =
    Elm.apply
        (Elm.value
             { importFrom = [ "ErrorPage" ]
             , name = "statusCode"
             , annotation =
                 Just
                     (Type.function
                          [ Type.namedWith [ "ErrorPage" ] "ErrorPage" [] ]
                          (Type.var "number")
                     )
             }
        )
        [ statusCodeArg ]


{-| view: ErrorPage.ErrorPage -> ErrorPage.Model -> View.View ErrorPage.Msg -}
view : Elm.Expression -> Elm.Expression -> Elm.Expression
view viewArg viewArg0 =
    Elm.apply
        (Elm.value
             { importFrom = [ "ErrorPage" ]
             , name = "view"
             , annotation =
                 Just
                     (Type.function
                          [ Type.namedWith [ "ErrorPage" ] "ErrorPage" []
                          , Type.namedWith [ "ErrorPage" ] "Model" []
                          ]
                          (Type.namedWith
                               [ "View" ]
                               "View"
                               [ Type.namedWith [ "ErrorPage" ] "Msg" [] ]
                          )
                     )
             }
        )
        [ viewArg, viewArg0 ]


{-| internalError: String -> ErrorPage.ErrorPage -}
internalError : String -> Elm.Expression
internalError internalErrorArg =
    Elm.apply
        (Elm.value
             { importFrom = [ "ErrorPage" ]
             , name = "internalError"
             , annotation =
                 Just
                     (Type.function
                          [ Type.string ]
                          (Type.namedWith [ "ErrorPage" ] "ErrorPage" [])
                     )
             }
        )
        [ Elm.string internalErrorArg ]


{-| notFound: ErrorPage.ErrorPage -}
notFound : Elm.Expression
notFound =
    Elm.value
        { importFrom = [ "ErrorPage" ]
        , name = "notFound"
        , annotation = Just (Type.namedWith [ "ErrorPage" ] "ErrorPage" [])
        }


{-| head: ErrorPage.ErrorPage -> List Head.Tag -}
head : Elm.Expression -> Elm.Expression
head headArg =
    Elm.apply
        (Elm.value
             { importFrom = [ "ErrorPage" ]
             , name = "head"
             , annotation =
                 Just
                     (Type.function
                          [ Type.namedWith [ "ErrorPage" ] "ErrorPage" [] ]
                          (Type.list (Type.namedWith [ "Head" ] "Tag" []))
                     )
             }
        )
        [ headArg ]


{-| update: 
    ErrorPage.ErrorPage
    -> ErrorPage.Msg
    -> ErrorPage.Model
    -> ( ErrorPage.Model, Effect.Effect ErrorPage.Msg )
-}
update : Elm.Expression -> Elm.Expression -> Elm.Expression -> Elm.Expression
update updateArg updateArg0 updateArg1 =
    Elm.apply
        (Elm.value
             { importFrom = [ "ErrorPage" ]
             , name = "update"
             , annotation =
                 Just
                     (Type.function
                          [ Type.namedWith [ "ErrorPage" ] "ErrorPage" []
                          , Type.namedWith [ "ErrorPage" ] "Msg" []
                          , Type.namedWith [ "ErrorPage" ] "Model" []
                          ]
                          (Type.tuple
                               (Type.namedWith [ "ErrorPage" ] "Model" [])
                               (Type.namedWith
                                    [ "Effect" ]
                                    "Effect"
                                    [ Type.namedWith [ "ErrorPage" ] "Msg" [] ]
                               )
                          )
                     )
             }
        )
        [ updateArg, updateArg0, updateArg1 ]


{-| init: ErrorPage.ErrorPage -> ( ErrorPage.Model, Effect.Effect ErrorPage.Msg ) -}
init : Elm.Expression -> Elm.Expression
init initArg =
    Elm.apply
        (Elm.value
             { importFrom = [ "ErrorPage" ]
             , name = "init"
             , annotation =
                 Just
                     (Type.function
                          [ Type.namedWith [ "ErrorPage" ] "ErrorPage" [] ]
                          (Type.tuple
                               (Type.namedWith [ "ErrorPage" ] "Model" [])
                               (Type.namedWith
                                    [ "Effect" ]
                                    "Effect"
                                    [ Type.namedWith [ "ErrorPage" ] "Msg" [] ]
                               )
                          )
                     )
             }
        )
        [ initArg ]


annotation_ :
    { model : Type.Annotation
    , errorPage : Type.Annotation
    , msg : Type.Annotation
    }
annotation_ =
    { model =
        Type.alias
            moduleName_
            "Model"
            []
            (Type.record [ ( "count", Type.int ) ])
    , errorPage = Type.namedWith [ "ErrorPage" ] "ErrorPage" []
    , msg = Type.namedWith [ "ErrorPage" ] "Msg" []
    }


make_ :
    { model : { count : Elm.Expression } -> Elm.Expression
    , notFound : Elm.Expression
    , internalError : Elm.Expression -> Elm.Expression
    }
make_ =
    { model =
        \model_args ->
            Elm.withType
                (Type.alias
                     [ "ErrorPage" ]
                     "Model"
                     []
                     (Type.record [ ( "count", Type.int ) ])
                )
                (Elm.record [ Tuple.pair "count" model_args.count ])
    , notFound =
        Elm.value
            { importFrom = [ "ErrorPage" ]
            , name = "NotFound"
            , annotation = Just (Type.namedWith [] "ErrorPage" [])
            }
    , internalError =
        \ar0 ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "ErrorPage" ]
                     , name = "InternalError"
                     , annotation = Just (Type.namedWith [] "ErrorPage" [])
                     }
                )
                [ ar0 ]
    }


caseOf_ :
    { errorPage :
        Elm.Expression
        -> { errorPageTags_0_0
            | notFound : Elm.Expression
            , internalError : Elm.Expression -> Elm.Expression
        }
        -> Elm.Expression
    }
caseOf_ =
    { errorPage =
        \errorPageExpression errorPageTags ->
            Elm.Case.custom
                errorPageExpression
                (Type.namedWith [ "ErrorPage" ] "ErrorPage" [])
                [ Elm.Case.branch0 "NotFound" errorPageTags.notFound
                , Elm.Case.branch1
                    "InternalError"
                    ( "stringString", Type.string )
                    errorPageTags.internalError
                ]
    }


call_ :
    { statusCode : Elm.Expression -> Elm.Expression
    , view : Elm.Expression -> Elm.Expression -> Elm.Expression
    , internalError : Elm.Expression -> Elm.Expression
    , head : Elm.Expression -> Elm.Expression
    , update :
        Elm.Expression -> Elm.Expression -> Elm.Expression -> Elm.Expression
    , init : Elm.Expression -> Elm.Expression
    }
call_ =
    { statusCode =
        \statusCodeArg ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "ErrorPage" ]
                     , name = "statusCode"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.namedWith
                                      [ "ErrorPage" ]
                                      "ErrorPage"
                                      []
                                  ]
                                  (Type.var "number")
                             )
                     }
                )
                [ statusCodeArg ]
    , view =
        \viewArg viewArg0 ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "ErrorPage" ]
                     , name = "view"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.namedWith
                                      [ "ErrorPage" ]
                                      "ErrorPage"
                                      []
                                  , Type.namedWith [ "ErrorPage" ] "Model" []
                                  ]
                                  (Type.namedWith
                                       [ "View" ]
                                       "View"
                                       [ Type.namedWith [ "ErrorPage" ] "Msg" []
                                       ]
                                  )
                             )
                     }
                )
                [ viewArg, viewArg0 ]
    , internalError =
        \internalErrorArg ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "ErrorPage" ]
                     , name = "internalError"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.string ]
                                  (Type.namedWith [ "ErrorPage" ] "ErrorPage" []
                                  )
                             )
                     }
                )
                [ internalErrorArg ]
    , head =
        \headArg ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "ErrorPage" ]
                     , name = "head"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.namedWith
                                      [ "ErrorPage" ]
                                      "ErrorPage"
                                      []
                                  ]
                                  (Type.list
                                       (Type.namedWith [ "Head" ] "Tag" [])
                                  )
                             )
                     }
                )
                [ headArg ]
    , update =
        \updateArg updateArg0 updateArg1 ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "ErrorPage" ]
                     , name = "update"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.namedWith
                                      [ "ErrorPage" ]
                                      "ErrorPage"
                                      []
                                  , Type.namedWith [ "ErrorPage" ] "Msg" []
                                  , Type.namedWith [ "ErrorPage" ] "Model" []
                                  ]
                                  (Type.tuple
                                       (Type.namedWith
                                            [ "ErrorPage" ]
                                            "Model"
                                            []
                                       )
                                       (Type.namedWith
                                            [ "Effect" ]
                                            "Effect"
                                            [ Type.namedWith
                                                [ "ErrorPage" ]
                                                "Msg"
                                                []
                                            ]
                                       )
                                  )
                             )
                     }
                )
                [ updateArg, updateArg0, updateArg1 ]
    , init =
        \initArg ->
            Elm.apply
                (Elm.value
                     { importFrom = [ "ErrorPage" ]
                     , name = "init"
                     , annotation =
                         Just
                             (Type.function
                                  [ Type.namedWith
                                      [ "ErrorPage" ]
                                      "ErrorPage"
                                      []
                                  ]
                                  (Type.tuple
                                       (Type.namedWith
                                            [ "ErrorPage" ]
                                            "Model"
                                            []
                                       )
                                       (Type.namedWith
                                            [ "Effect" ]
                                            "Effect"
                                            [ Type.namedWith
                                                [ "ErrorPage" ]
                                                "Msg"
                                                []
                                            ]
                                       )
                                  )
                             )
                     }
                )
                [ initArg ]
    }


values_ :
    { statusCode : Elm.Expression
    , view : Elm.Expression
    , internalError : Elm.Expression
    , notFound : Elm.Expression
    , head : Elm.Expression
    , update : Elm.Expression
    , init : Elm.Expression
    }
values_ =
    { statusCode =
        Elm.value
            { importFrom = [ "ErrorPage" ]
            , name = "statusCode"
            , annotation =
                Just
                    (Type.function
                         [ Type.namedWith [ "ErrorPage" ] "ErrorPage" [] ]
                         (Type.var "number")
                    )
            }
    , view =
        Elm.value
            { importFrom = [ "ErrorPage" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                         [ Type.namedWith [ "ErrorPage" ] "ErrorPage" []
                         , Type.namedWith [ "ErrorPage" ] "Model" []
                         ]
                         (Type.namedWith
                              [ "View" ]
                              "View"
                              [ Type.namedWith [ "ErrorPage" ] "Msg" [] ]
                         )
                    )
            }
    , internalError =
        Elm.value
            { importFrom = [ "ErrorPage" ]
            , name = "internalError"
            , annotation =
                Just
                    (Type.function
                         [ Type.string ]
                         (Type.namedWith [ "ErrorPage" ] "ErrorPage" [])
                    )
            }
    , notFound =
        Elm.value
            { importFrom = [ "ErrorPage" ]
            , name = "notFound"
            , annotation = Just (Type.namedWith [ "ErrorPage" ] "ErrorPage" [])
            }
    , head =
        Elm.value
            { importFrom = [ "ErrorPage" ]
            , name = "head"
            , annotation =
                Just
                    (Type.function
                         [ Type.namedWith [ "ErrorPage" ] "ErrorPage" [] ]
                         (Type.list (Type.namedWith [ "Head" ] "Tag" []))
                    )
            }
    , update =
        Elm.value
            { importFrom = [ "ErrorPage" ]
            , name = "update"
            , annotation =
                Just
                    (Type.function
                         [ Type.namedWith [ "ErrorPage" ] "ErrorPage" []
                         , Type.namedWith [ "ErrorPage" ] "Msg" []
                         , Type.namedWith [ "ErrorPage" ] "Model" []
                         ]
                         (Type.tuple
                              (Type.namedWith [ "ErrorPage" ] "Model" [])
                              (Type.namedWith
                                   [ "Effect" ]
                                   "Effect"
                                   [ Type.namedWith [ "ErrorPage" ] "Msg" [] ]
                              )
                         )
                    )
            }
    , init =
        Elm.value
            { importFrom = [ "ErrorPage" ]
            , name = "init"
            , annotation =
                Just
                    (Type.function
                         [ Type.namedWith [ "ErrorPage" ] "ErrorPage" [] ]
                         (Type.tuple
                              (Type.namedWith [ "ErrorPage" ] "Model" [])
                              (Type.namedWith
                                   [ "Effect" ]
                                   "Effect"
                                   [ Type.namedWith [ "ErrorPage" ] "Msg" [] ]
                              )
                         )
                    )
            }
    }