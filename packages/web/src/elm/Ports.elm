port module Ports exposing
    ( onPointerCancel, onPointerDown, onPointerMove, onPointerUp
    , wsOpen, wsSend, wsClose, wsOnOpen, wsOnClose, wsOnMessage, wsOnError
    , mmAsyncError, mmClose, mmCreateWebhook, mmOnMessage, mmOpen, mmPublish
    , mmPushList, mmResponse, mmSubscribe
    )

{-| Application ports


# Pointer

@docs onPointerCancel, onPointerDown, onPointerMove, onPointerUp


# Raw Websockets

@docs wsOpen, wsSend, wsClose, wsOnOpen, wsOnClose, wsOnMessage, wsOnError


# Momento Cache

@docs mmAsyncError, mmClose, mmCreateWebhook, mmOnMessage, mmOpen, mmPublish
@docs mmPushList, mmResponse, mmSubscribe

-}

import Json.Encode exposing (Value)



-- HTML Pointer API


port onPointerDown : (Value -> msg) -> Sub msg


port onPointerUp : (Value -> msg) -> Sub msg


port onPointerMove : (Value -> msg) -> Sub msg


port onPointerCancel : (Value -> msg) -> Sub msg



-- Websockets API


port wsOpen : { id : String, url : String } -> Cmd msg


port wsSend : { id : String, payload : String } -> Cmd msg


port wsClose : String -> Cmd msg


port wsOnOpen : (String -> msg) -> Sub msg


port wsOnClose : (String -> msg) -> Sub msg


port wsOnMessage : ({ id : String, payload : String } -> msg) -> Sub msg


port wsOnError : ({ id : String, error : Value } -> msg) -> Sub msg



-- Momento API


port mmOpen : { id : String, cache : String, apiKey : String } -> Cmd msg


port mmClose : { id : String, session : Value } -> Cmd msg


port mmSubscribe : { id : String, session : Value, topic : String } -> Cmd msg


port mmPublish : { id : String, session : Value, topic : String, payload : String } -> Cmd msg


port mmOnMessage : ({ id : String, session : Value, payload : String } -> msg) -> Sub msg


port mmPushList : { id : String, session : Value, list : String, payload : String } -> Cmd msg


port mmCreateWebhook : { id : String, session : Value, name : String, topic : String, url : String } -> Cmd msg


port mmResponse : ({ id : String, type_ : String, response : Value } -> msg) -> Sub msg


port mmAsyncError : ({ id : String, error : Value } -> msg) -> Sub msg
