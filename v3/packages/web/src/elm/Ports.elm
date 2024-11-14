port module Ports exposing
    ( onPointerCancel, onPointerDown, onPointerMove, onPointerUp
    , wsOpen, wsSend, wsClose, wsOnOpen, wsOnClose, wsOnMessage, wsOnError
    , mmClose, mmOnClose, mmOnError, mmOnMessage, mmOnOpen, mmOpen, mmPushList
    , mmSend, mmOnSubscribe, mmSubscribe
    )

{-| Application ports


# Pointer

@docs onPointerCancel, onPointerDown, onPointerMove, onPointerUp


# Raw Websockets

@docs wsOpen, wsSend, wsClose, wsOnOpen, wsOnClose, wsOnMessage, wsOnError


# Momento Cache

@docs mmClose, mmOnClose, mmOnError, mmOnMessage, mmOnOpen, mmOpen, mmPushList
@docs mmSend, mmOnSubscribe, mmSubscribe

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


port mmOnOpen : (String -> msg) -> Sub msg


port mmClose : String -> Cmd msg


port mmOnClose : (String -> msg) -> Sub msg


port mmSubscribe : { id : String, topic : String } -> Cmd msg


port mmOnSubscribe : ({ id : String, topic : String } -> msg) -> Sub msg


port mmSend : { id : String, topic : String, payload : String } -> Cmd msg


port mmOnMessage : ({ id : String, payload : String } -> msg) -> Sub msg


port mmPushList : { id : String, list : String, payload : String } -> Cmd msg


port mmOnError : ({ id : String, error : Value } -> msg) -> Sub msg
