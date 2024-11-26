module Momento exposing
    ( Error(..)
    , Model
    , MomentoApi
    , Msg(..)
    , Op
    , OpenParams
    , Ports
    , Protocol
    , Session(..)
    , SessionKey
    , SubscribeParams
    , init
    , momentoApi
    , oldOpen
    , oldProcessOps
    , oldSubscribe
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
import Procedure
import Procedure.Channel as Channel
import Procedure.Program
import Update2 as U2


type alias Ports msg =
    { open : { id : String, cache : String, apiKey : String } -> Cmd msg
    , onOpen : ({ id : String, session : Value } -> msg) -> Sub msg
    , close : { id : String, session : Value } -> Cmd msg
    , subscribe : { id : String, session : Value, topic : String } -> Cmd msg
    , onSubscribe : ({ id : String, session : Value, topic : String } -> msg) -> Sub msg
    , publish : { id : String, session : Value, topic : String, payload : String } -> Cmd msg
    , onMessage : ({ id : String, session : Value, payload : String } -> msg) -> Sub msg
    , pushList : { id : String, session : Value, list : String, payload : String } -> Cmd msg
    , createWebhook : { id : String, session : Value, topic : String, url : String } -> Cmd msg
    , onError : ({ id : String, error : Value } -> msg) -> Sub msg
    }


type alias MomentoApi msg =
    { open :
        OpenParams
        -> (Result Error SessionKey -> msg)
        -> Cmd msg
    , subscribe :
        SessionKey
        -> SubscribeParams
        -> (Result Error { session : SessionKey, topic : String } -> msg)
        -> Cmd msg
    , processOps :
        SessionKey
        -> List Op
        -> (Result Error () -> msg)
        -> Cmd msg
    }


momentoApi : (Procedure.Program.Msg msg -> msg) -> Ports msg -> MomentoApi msg
momentoApi pt ports =
    { open = open pt ports
    , subscribe = subscribe pt ports
    , processOps = processOps pt ports
    }


type SessionKey
    = SessionKey Value


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



--===


type Msg
    = SessionOpened { id : String, session : Value }
    | OnSubscribe { id : String, session : Value, topic : String }
    | OnMessage { id : String, session : Value, payload : String }
    | OnError { id : String, error : Value }


type alias Model =
    { sessions : Dict String Session
    }


type Session
    = Closed
    | Open SessionKey


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , ports : Ports Msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onOpen : String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onSubscribe : String -> SubscribeParams -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onMessage : String -> String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onError : String -> Error -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> Ports msg -> ( Model, Cmd msg )
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



--===


open :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> OpenParams
    -> (Result Error SessionKey -> msg)
    -> Cmd msg
open pt ports openParams dt =
    Channel.open (\key -> ports.open { id = key, cache = openParams.cache, apiKey = openParams.apiKey })
        |> Channel.connect ports.onOpen
        |> Channel.filter (\key { id, session } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ session } -> SessionKey session |> Ok |> dt)


subscribe :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> SessionKey
    -> SubscribeParams
    -> (Result Error { session : SessionKey, topic : String } -> msg)
    -> Cmd msg
subscribe pt ports (SessionKey sessionKey) subscribeParams dt =
    Channel.open (\key -> ports.subscribe { id = key, session = sessionKey, topic = subscribeParams.topic })
        |> Channel.connect ports.onSubscribe
        |> Channel.filter (\key { id, session } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ session, topic } -> { session = SessionKey session, topic = topic } |> Ok |> dt)


processOps :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> SessionKey
    -> List Op
    -> (Result Error () -> msg)
    -> Cmd msg
processOps pt ports (SessionKey sessionKey) ops dt =
    innerProcessOps ports (SessionKey sessionKey) ops
        |> Procedure.run pt dt


publish : { topic : String, payload : String } -> Op
publish args =
    Publish args


pushList : { list : String, payload : String } -> Op
pushList args =
    PushList args


webhook : { topic : String, url : String } -> Op
webhook args =
    Webhook args


innerProcessOps :
    Ports msg
    -> SessionKey
    -> List Op
    -> Procedure.Procedure Never (Result error ()) msg
innerProcessOps ports (SessionKey sessionKey) ops =
    case ops of
        [] ->
            Procedure.provide (Ok ())

        op :: remOps ->
            Procedure.do (processOp ports "" (SessionKey sessionKey) op)
                |> Procedure.map Ok
                |> Procedure.andThen (\_ -> innerProcessOps ports (SessionKey sessionKey) remOps)


processOp : Ports msg -> String -> SessionKey -> Op -> Cmd msg
processOp ports id (SessionKey sessionKey) op =
    case op of
        Publish { topic, payload } ->
            ports.publish { id = id, session = sessionKey, topic = topic, payload = payload }

        PushList { list, payload } ->
            ports.pushList { id = id, session = sessionKey, list = list, payload = payload }

        Webhook { topic, url } ->
            ports.createWebhook { id = id, session = sessionKey, topic = topic, url = url }



--===


oldOpen : Protocol Model msg model -> String -> OpenParams -> Model -> ( model, Cmd msg )
oldOpen protocol id props model =
    ( model
    , protocol.ports.open
        { id = id
        , cache = props.cache
        , apiKey = props.apiKey
        }
        |> Cmd.map protocol.toMsg
    )
        |> protocol.onUpdate


oldSubscribe : Protocol Model msg model -> String -> SubscribeParams -> Model -> ( model, Cmd msg )
oldSubscribe protocol id props model =
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


oldProcessOps : Protocol Model msg model -> String -> List Op -> Model -> ( model, Cmd msg )
oldProcessOps protocol id ops model =
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
                        (oldProcessOp protocol id key)
                        ops
            in
            ( model
            , portCmds |> Cmd.batch
            )
                |> protocol.onUpdate

        _ ->
            U2.pure model
                |> protocol.onUpdate


oldProcessOp : Protocol Model msg model -> String -> Value -> Op -> Cmd msg
oldProcessOp protocol id key op =
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
