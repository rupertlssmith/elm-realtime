module Websockets exposing (Model, Msg(..), Ports, Protocol, Socket(..), init, open, send, subscriptions, update)

import Dict exposing (Dict)
import Update2 as U2


type Msg
    = SocketOpened String
    | OnMessage { id : String, payload : String }


type alias Model =
    { sockets : Dict String Socket
    }


type Socket
    = Closed
    | Open


type alias Ports =
    { open : { id : String, url : String } -> Cmd Msg
    , onOpen : (String -> Msg) -> Sub Msg
    , send : { id : String, payload : String } -> Cmd Msg
    , onMessage : ({ id : String, payload : String } -> Msg) -> Sub Msg
    , close : String -> Cmd Msg
    }


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , ports : Ports
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onOpen : String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onMessage : String -> String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> Ports -> ( Model, Cmd msg )
init _ _ =
    ( { sockets = Dict.empty
      }
    , Cmd.none
    )


subscriptions : Protocol Model msg model -> Model -> Sub msg
subscriptions protocol _ =
    [ protocol.ports.onOpen SocketOpened
    , protocol.ports.onMessage OnMessage
    ]
        |> Sub.batch
        |> Sub.map protocol.toMsg


update : Protocol Model msg model -> Msg -> Model -> ( model, Cmd msg )
update protocol msg model =
    case msg of
        SocketOpened id ->
            let
                sockets =
                    Dict.insert id Open model.sockets
            in
            U2.pure { model | sockets = sockets }
                |> protocol.onOpen id

        OnMessage { id, payload } ->
            let
                _ =
                    Debug.log "OnMessage" msg
            in
            U2.pure model
                |> protocol.onMessage id payload


open : Protocol Model msg model -> String -> String -> Model -> ( model, Cmd msg )
open protocol id url model =
    ( model
    , protocol.ports.open { id = id, url = url }
        |> Cmd.map protocol.toMsg
    )
        |> protocol.onUpdate


send : Protocol Model msg model -> String -> String -> Model -> ( model, Cmd msg )
send protocol id payload model =
    let
        socket =
            Dict.get id model.sockets
    in
    case socket of
        Just Open ->
            ( model
            , protocol.ports.send { id = id, payload = payload }
                |> Cmd.map protocol.toMsg
            )
                |> protocol.onUpdate

        _ ->
            U2.pure model
                |> protocol.onUpdate
