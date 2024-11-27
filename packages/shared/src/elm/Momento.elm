module Momento exposing
    ( Error(..)
    , MomentoApi
    , MomentoSessionKey
    , OpenParams
    , Ports
    , PublishParams
    , PushListParams
    , SubscribeParams
    , WebhookParams
    , errorToString
    , momentoApi
    )

import Json.Encode exposing (Value)
import Procedure
import Procedure.Channel as Channel
import Procedure.Program



-- API


type alias Ports msg =
    { open : { id : String, cache : String, apiKey : String } -> Cmd msg
    , close : { id : String, session : Value } -> Cmd msg
    , subscribe : { id : String, session : Value, topic : String } -> Cmd msg
    , publish : { id : String, session : Value, topic : String, payload : String } -> Cmd msg
    , onMessage : ({ id : String, session : Value, payload : String } -> msg) -> Sub msg
    , pushList : { id : String, session : Value, list : String, payload : String } -> Cmd msg
    , createWebhook : { id : String, session : Value, topic : String, url : String } -> Cmd msg
    , response : ({ id : String, type_ : String, response : Value } -> msg) -> Sub msg
    , asyncError : ({ id : String, error : Value } -> msg) -> Sub msg
    }


type alias MomentoApi msg =
    { open : OpenParams -> (Result Error MomentoSessionKey -> msg) -> Cmd msg
    , subscribe : MomentoSessionKey -> SubscribeParams -> (Result Error MomentoSessionKey -> msg) -> Cmd msg
    , pushList : MomentoSessionKey -> PushListParams -> (Result Error MomentoSessionKey -> msg) -> Cmd msg
    , webhook : MomentoSessionKey -> WebhookParams -> (Result Error MomentoSessionKey -> msg) -> Cmd msg
    , publish : MomentoSessionKey -> PublishParams -> Cmd msg
    }


momentoApi : (Procedure.Program.Msg msg -> msg) -> Ports msg -> MomentoApi msg
momentoApi pt ports =
    { open = open pt ports
    , subscribe = subscribe pt ports
    , pushList = pushList pt ports
    , webhook = webhook pt ports
    , publish = publish ports
    }


type MomentoSessionKey
    = MomentoSessionKey Value


type alias OpenParams =
    { cache : String, apiKey : String }


type alias SubscribeParams =
    { topic : String }


type alias PublishParams =
    { topic : String, payload : String }


type alias PushListParams =
    { list : String, payload : String }


type alias WebhookParams =
    { topic : String, url : String }


type Error
    = Failed


errorToString : Error -> String
errorToString _ =
    "Momento Error"



-- Implementation


decodeResponse : { a | type_ : String, response : Value } -> Result Error MomentoSessionKey
decodeResponse res =
    case res.type_ of
        "Ok" ->
            MomentoSessionKey res.response |> Ok

        "Error" ->
            Err Failed

        _ ->
            Err Failed


open :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> OpenParams
    -> (Result Error MomentoSessionKey -> msg)
    -> Cmd msg
open pt ports openParams dt =
    Channel.open (\key -> ports.open { id = key, cache = openParams.cache, apiKey = openParams.apiKey })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\res -> decodeResponse res |> dt)


subscribe :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> MomentoSessionKey
    -> SubscribeParams
    -> (Result Error MomentoSessionKey -> msg)
    -> Cmd msg
subscribe pt ports (MomentoSessionKey sessionKey) subscribeParams dt =
    Channel.open (\key -> ports.subscribe { id = key, session = sessionKey, topic = subscribeParams.topic })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\res -> decodeResponse res |> dt)


pushList :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> MomentoSessionKey
    -> PushListParams
    -> (Result Error MomentoSessionKey -> msg)
    -> Cmd msg
pushList pt ports (MomentoSessionKey sessionKey) { list, payload } dt =
    Channel.open (\key -> ports.pushList { id = key, session = sessionKey, list = list, payload = payload })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\res -> decodeResponse res |> dt)


webhook :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> MomentoSessionKey
    -> WebhookParams
    -> (Result Error MomentoSessionKey -> msg)
    -> Cmd msg
webhook pt ports (MomentoSessionKey sessionKey) { topic, url } dt =
    Channel.open (\key -> ports.createWebhook { id = key, session = sessionKey, topic = topic, url = url })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\res -> decodeResponse res |> dt)


{-| Publishes a message on a topic. Publish is asynchronous and will not generate a response message in Elm,
but may report errors on the asyncError subscription.
-}
publish : Ports msg -> MomentoSessionKey -> PublishParams -> Cmd msg
publish ports (MomentoSessionKey sessionKey) { topic, payload } =
    ports.publish { id = "", session = sessionKey, topic = topic, payload = payload }



-- Batched operations
--type Op
--    = Publish { topic : String, payload : String }
--    | PushList { list : String, payload : String }
--    | Webhook { topic : String, url : String }
--
--publishOp : { topic : String, payload : String } -> Op
--publishOp args =
--    Publish args
--
--
--pushListOp : { list : String, payload : String } -> Op
--pushListOp args =
--    PushList args
--
--
--webhookOp : WebhookParams -> Op
--webhookOp args =
--    Webhook args
--
--
--processOps :
--    (Procedure.Program.Msg msg -> msg)
--    -> Ports msg
--    -> SessionKey
--    -> List Op
--    -> (Result Error () -> msg)
--    -> Cmd msg
--processOps pt ports (SessionKey sessionKey) ops dt =
--    innerProcessOps ports (SessionKey sessionKey) ops
--        |> Procedure.run pt dt
--
--
--innerProcessOps :
--    Ports msg
--    -> SessionKey
--    -> List Op
--    -> Procedure.Procedure Never (Result error ()) msg
--innerProcessOps ports (SessionKey sessionKey) ops =
--    case ops of
--        [] ->
--            Procedure.provide (Ok ())
--
--        op :: remOps ->
--            Procedure.do (processOp ports "" (SessionKey sessionKey) op)
--                |> Procedure.map Ok
--                |> Procedure.andThen (\_ -> innerProcessOps ports (SessionKey sessionKey) remOps)
--
--
--processOp : Ports msg -> String -> SessionKey -> Op -> Cmd msg
--processOp ports id (SessionKey sessionKey) op =
--    case op of
--        Publish { topic, payload } ->
--            ports.publish { id = id, session = sessionKey, topic = topic, payload = payload }
--
--        PushList { list, payload } ->
--            ports.pushList { id = id, session = sessionKey, list = list, payload = payload }
--
--        Webhook { topic, url } ->
--            ports.createWebhook { id = id, session = sessionKey, topic = topic, url = url }
