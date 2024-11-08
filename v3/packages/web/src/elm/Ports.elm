port module Ports exposing
    ( onPointerCancel
    , onPointerDown
    , onPointerMove
    , onPointerUp
    , wsClose
    , wsOnClose
    , wsOnError
    , wsOnMessage
    , wsOnOpen
    , wsOpen
    , wsSend
    )

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
