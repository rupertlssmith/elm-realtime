module Momento exposing
    ( Error(..)
    , Model
    , Msg(..)
    , Op
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
    , webhook
    )

import Dict exposing (Dict)
import Json.Encode exposing (Value)
import Update2 as U2


type Msg
    = SessionOpened { id : String, session : Value }
    | OnSubscribe { id : String, session : Value, topic : String }
    | OnMessage { id : String, session : Value, payload : String }
    | OnError { id : String, error : Value }


type alias Model =
    { sessions : Dict String Session
    }


type SessionKey
    = SessionKey Value


type Session
    = Closed
    | Open SessionKey


type alias OpenParams =
    { cache : String, apiKey : String }


type alias SubscribeParams =
    { topic : String }


type Error
    = Failed


type Op
    = Publish { topic : String, payload : String }
    | PushList { list : String, payload : String }
    | Webhook { topic : String, url : String }


type alias Ports =
    { open : { id : String, cache : String, apiKey : String } -> Cmd Msg
    , onOpen : ({ id : String, session : Value } -> Msg) -> Sub Msg
    , close : { id : String, session : Value } -> Cmd Msg
    , subscribe : { id : String, session : Value, topic : String } -> Cmd Msg
    , onSubscribe : ({ id : String, session : Value, topic : String } -> Msg) -> Sub Msg
    , publish : { id : String, session : Value, topic : String, payload : String } -> Cmd Msg
    , onMessage : ({ id : String, session : Value, payload : String } -> Msg) -> Sub Msg
    , pushList : { id : String, session : Value, list : String, payload : String } -> Cmd Msg
    , createWebhook : { id : String, session : Value, topic : String, url : String } -> Cmd Msg
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
    , protocol.ports.onSubscribe OnSubscribe
    , protocol.ports.onMessage OnMessage
    , protocol.ports.onError OnError
    ]
        |> Sub.batch
        |> Sub.map protocol.toMsg


update : Protocol Model msg model -> Msg -> Model -> ( model, Cmd msg )
update protocol msg model =
    case Debug.log "Momento.update" msg of
        SessionOpened { id, session } ->
            let
                sockets =
                    Dict.insert id (SessionKey session |> Open) model.sessions
            in
            U2.pure { model | sessions = sockets }
                |> protocol.onOpen id

        OnSubscribe { id, topic } ->
            U2.pure model
                |> protocol.onSubscribe id { topic = topic }

        OnMessage { id, payload } ->
            U2.pure model
                |> protocol.onMessage id payload

        OnError { id } ->
            U2.pure model
                |> protocol.onError id Failed



--


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
    let
        session =
            Dict.get id model.sessions
    in
    case session of
        Just (Open (SessionKey key)) ->
            ( model
            , protocol.ports.subscribe
                { id = id
                , session = key
                , topic = props.topic
                }
                |> Cmd.map protocol.toMsg
            )
                |> protocol.onUpdate

        _ ->
            U2.pure model
                |> protocol.onUpdate


processOps : Protocol Model msg model -> String -> List Op -> Model -> ( model, Cmd msg )
processOps protocol id ops model =
    let
        session =
            Dict.get id model.sessions

        _ =
            Debug.log "Momento.processOps" ( id, ops, session )
    in
    case session of
        Just (Open (SessionKey key)) ->
            let
                portCmds =
                    List.map
                        (processOp protocol id key)
                        ops
            in
            ( model
            , portCmds |> Cmd.batch
            )
                |> protocol.onUpdate

        _ ->
            U2.pure model
                |> protocol.onUpdate


processOp : Protocol Model msg model -> String -> Value -> Op -> Cmd msg
processOp protocol id key op =
    case op of
        Publish { topic, payload } ->
            protocol.ports.publish { id = id, session = key, topic = topic, payload = payload }
                |> Cmd.map protocol.toMsg

        PushList { list, payload } ->
            protocol.ports.pushList { id = id, session = key, list = list, payload = payload }
                |> Cmd.map protocol.toMsg

        Webhook { topic, url } ->
            protocol.ports.createWebhook { id = id, session = key, topic = topic, url = url }
                |> Cmd.map protocol.toMsg


publish : { topic : String, payload : String } -> Op
publish args =
    Publish args


pushList : { list : String, payload : String } -> Op
pushList args =
    PushList args


webhook : { topic : String, url : String } -> Op
webhook args =
    Webhook args
