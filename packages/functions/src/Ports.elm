port module Ports exposing
    ( requestPort, responsePort
    , mmClose, mmOnClose, mmOnError, mmOnMessage, mmOnOpen, mmOpen, mmPushList
    , mmSend, mmOnSubscribe, mmSubscribe
    )

{-| Application ports


# AWS Lambda ports

@docs requestPort, responsePort


# Momento Cache

@docs mmClose, mmOnClose, mmOnError, mmOnMessage, mmOnOpen, mmOpen, mmPushList
@docs mmSend, mmOnSubscribe, mmSubscribe

-}

import Json.Encode exposing (Value)



-- AWS Lambda ports


port requestPort : (( String, Value, Value ) -> msg) -> Sub msg


port responsePort : ( String, Value, Value ) -> Cmd msg



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
