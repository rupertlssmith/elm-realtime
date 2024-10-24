module App.Component exposing (..)

import Html.Styled as Html exposing (Html)
import Http
import Random
import Update2 as U2
import Websockets exposing (Error)


type alias Component a =
    { a
        | app : Model
    }


setModel m x =
    { m | app = x }


type Msg
    = RandomSeed Random.Seed
    | LoggedIn (Result Http.Error ())


type Model
    = ModelStart StartState
    | ModelRandomized RandomizedState
    | ModelLoggedIn LoggedInState
    | ModelConnected ConnectedState


type alias StartState =
    { log : List String }


type alias RandomizedState =
    { log : List String
    , seed : Random.Seed
    }


type alias LoggedInState =
    { log : List String
    , seed : Random.Seed
    }


type alias ConnectedState =
    { log : List String
    , socketHandle : String
    , seed : Random.Seed
    }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )

    -- Websocket interface.
    , wsOpen : String -> String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , wsSend : String -> String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    { log = [ "Started" ] }
        |> U2.pure
        |> U2.andMap randomize
        |> U2.andMap (switchState ModelStart)
        |> Tuple.mapSecond (Cmd.map toMsg)


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.app
    in
    case ( model, msg ) of
        ( ModelStart state, RandomSeed seed ) ->
            { log = "Randomized" :: state.log
            , seed = seed
            }
                |> U2.pure
                |> U2.andThen login
                |> U2.andMap (switchState ModelRandomized)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelRandomized state, LoggedIn (Ok _) ) ->
            { log = "LoggedIn" :: state.log
            , seed = state.seed
            }
                |> U2.pure
                |> U2.andMap (switchState ModelLoggedIn)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.wsOpen "socket" "ws://localhost:8080"

        _ ->
            U2.pure component
                |> protocol.onUpdate


randomize : StartState -> ( StartState, Cmd Msg )
randomize model =
    ( model
    , Random.generate RandomSeed Random.independentSeed
    )


login : RandomizedState -> ( RandomizedState, Cmd Msg )
login model =
    ( model
    , Http.request
        { method = "POST"
        , headers =
            [--  Http.header "credentials" "include"
             --, Http.header "Access-Control-Allow-Origin" "*"
            ]
        , url = "http://localhost:8080/login"
        , body = Http.emptyBody
        , expect = Http.expectWhatever LoggedIn
        , timeout = Nothing
        , tracker = Nothing
        }
    )


wsOpened : Protocol (Component a) msg model -> String -> Component a -> ( model, Cmd msg )
wsOpened protocol id component =
    let
        model =
            component.app
    in
    case model of
        ModelLoggedIn state ->
            { log = "Connected" :: state.log
            , seed = state.seed
            , socketHandle = id
            }
                |> U2.pure
                |> U2.andMap (switchState ModelConnected)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.wsSend id "Hello!!"

        _ ->
            U2.pure component
                |> protocol.onUpdate


wsMessage : Protocol (Component a) msg model -> String -> String -> Component a -> ( model, Cmd msg )
wsMessage protocol id payload component =
    let
        model =
            component.app
    in
    case model of
        ModelConnected state ->
            { state | log = ("Message: " ++ payload) :: state.log }
                |> U2.pure
                |> U2.andMap (switchState ModelConnected)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate


wsError : Protocol (Component a) msg model -> String -> Error -> Component a -> ( model, Cmd msg )
wsError protocol id error component =
    let
        _ =
            Debug.log "wsError"
                { id = id
                , error = error
                }
    in
    component
        |> U2.pure
        |> protocol.onUpdate


view : Component a -> Html msg
view component =
    case component.app of
        ModelStart props ->
            logs props

        ModelRandomized props ->
            logs props

        ModelLoggedIn props ->
            logs props

        ModelConnected props ->
            logs props


logs : { a | log : List String } -> Html msg
logs model =
    List.foldl
        (\entry acc -> Html.text (entry ++ "\n") :: acc)
        []
        model.log
        |> Html.pre []
