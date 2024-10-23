module App.Component exposing (..)

import Random
import Update2 as U2


type alias Component a =
    { a
        | app : Model
    }


setModel m x =
    { m | app = x }


type Msg
    = RandomSeed Random.Seed


type Model
    = ModelStart StartState
    | ModelRandomized RandomizedState


type alias StartState =
    {}


type alias RandomizedState =
    { seed : Random.Seed
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
    {}
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
        ( ModelStart _, RandomSeed seed ) ->
            U2.pure
                { seed = seed
                }
                |> U2.andMap (switchState ModelRandomized)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                --|> protocol.onUpdate
                |> protocol.wsOpen "socket" "ws://localhost:8080"

        _ ->
            U2.pure component
                |> protocol.onUpdate


randomize : StartState -> ( StartState, Cmd Msg )
randomize model =
    ( model
    , Random.generate RandomSeed Random.independentSeed
    )


wsOpened : Protocol (Component a) msg model -> String -> Component a -> ( model, Cmd msg )
wsOpened protocol id component =
    Debug.todo "wsOpened"


wsMessage : Protocol (Component a) msg model -> String -> String -> Component a -> ( model, Cmd msg )
wsMessage protocol id payload component =
    Debug.todo "wsMessage"
