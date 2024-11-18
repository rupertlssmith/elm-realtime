module Momento exposing
    ( Error(..)
    , Model
    , Msg(..)
    , Op(..)
    , OpenParams
    , Ports
    , Protocol
    , Session(..)
    , SubscribeParams
    , init
    , open
    , processOps
    , publish
    , pushList
    , subscribe
    , subscriptions
    , update
    )

import Dict exposing (Dict)
import Json.Decode exposing (Value)
import Update2 as U2


type Msg
    = SessionOpened String
    | OnSubscribe { id : String, topic : String }
    | OnMessage { id : String, payload : String }
    | OnError { id : String, error : Value }


type alias Model =
    { sessions : Dict String Session
    }


type Session
    = Closed
    | Open


type alias OpenParams =
    { cache : String, apiKey : String }


type alias SubscribeParams =
    { topic : String }


type Error
    = Failed


type Op
    = Publish { topic : String, payload : String }
    | PushList { list : String, payload : String }


type alias Ports =
    { open : { id : String, cache : String, apiKey : String } -> Cmd Msg
    , onOpen : (String -> Msg) -> Sub Msg
    , close : String -> Cmd Msg
    , subscribe : { id : String, topic : String } -> Cmd Msg
    , onSunscribe : ({ id : String, topic : String } -> Msg) -> Sub Msg
    , publish : { id : String, topic : String, payload : String } -> Cmd Msg
    , onMessage : ({ id : String, payload : String } -> Msg) -> Sub Msg
    , pushList : { id : String, list : String, payload : String } -> Cmd Msg
    , onError : ({ id : String, error : Value } -> Msg) -> Sub Msg
    }


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , ports : Ports
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onOpen : String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onSubscribe : String -> SubscribeParams -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onMessage : String -> String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onError : String -> Error -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> Ports -> ( Model, Cmd msg )
init _ _ =
    ( { sessions = Dict.empty
      }
    , Cmd.none
    )


subscriptions : Protocol Model msg model -> Model -> Sub msg
subscriptions protocol _ =
    [ protocol.ports.onOpen SessionOpened
    , protocol.ports.onSunscribe OnSubscribe
    , protocol.ports.onMessage OnMessage
    , protocol.ports.onError OnError
    ]
        |> Sub.batch
        |> Sub.map protocol.toMsg


update : Protocol Model msg model -> Msg -> Model -> ( model, Cmd msg )
update protocol msg model =
    case Debug.log "Momento.update" msg of
        SessionOpened id ->
            let
                sockets =
                    Dict.insert id Open model.sessions
            in
            U2.pure { model | sessions = sockets }
                |> protocol.onOpen id

        OnSubscribe { id, topic } ->
            U2.pure model
                |> protocol.onSubscribe id { topic = topic }

        OnMessage { id, payload } ->
            U2.pure model
                |> protocol.onMessage id payload

        OnError { id, error } ->
            U2.pure model
                |> protocol.onError id Failed


open : Protocol Model msg model -> String -> OpenParams -> Model -> ( model, Cmd msg )
open protocol id props model =
    ( model
    , protocol.ports.open
        { id = id
        , cache = props.cache
        , apiKey = props.apiKey
        }
        |> Cmd.map protocol.toMsg
    )
        |> protocol.onUpdate


subscribe : Protocol Model msg model -> String -> SubscribeParams -> Model -> ( model, Cmd msg )
subscribe protocol id props model =
    ( model
    , protocol.ports.subscribe
        { id = id
        , topic = props.topic
        }
        |> Cmd.map protocol.toMsg
    )
        |> protocol.onUpdate


processOps : Protocol Model msg model -> String -> List Op -> Model -> ( model, Cmd msg )
processOps protocol id ops model =
    let
        socket =
            Dict.get id model.sessions
    in
    case socket of
        Just Open ->
            let
                portCmds =
                    List.map
                        (\op ->
                            case op of
                                Publish { topic, payload } ->
                                    protocol.ports.publish { id = id, topic = topic, payload = payload }
                                        |> Cmd.map protocol.toMsg

                                PushList { list, payload } ->
                                    protocol.ports.pushList { id = id, list = list, payload = payload }
                                        |> Cmd.map protocol.toMsg
                        )
                        ops
            in
            ( model
            , portCmds |> Cmd.batch
            )
                |> protocol.onUpdate

        _ ->
            U2.pure model
                |> protocol.onUpdate



--send : String -> {} -> Op


publish args =
    { topic = args.topic, payload = args.payload }
        |> Publish



--pushList : String -> {} -> Op


pushList args =
    { list = args.list, payload = args.payload }
        |> PushList
