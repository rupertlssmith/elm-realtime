port module Ports exposing
    ( requestPort, responsePort
    , mmClose, mmOnClose, mmOnError, mmOnMessage, mmOnOpen, mmOpen, mmPushList
    , mmSend, mmOnSubscribe, mmSubscribe
    , mmCreateWebhook
    , dynamoBatchGet, dynamoBatchWrite, dynamoDelete, dynamoGet, dynamoPut
    , dynamoQuery, dynamoResponse
    )

{-| Application ports


# AWS Lambda ports

@docs requestPort, responsePort


# Momento Cache

@docs mmClose, mmOnClose, mmOnError, mmOnMessage, mmOnOpen, mmOpen, mmPushList
@docs mmSend, mmOnSubscribe, mmSubscribe
@docs mmCreateWebhook


# AWS Dynamo DB

@docs dynamoBatchGet, dynamoBatchWrite, dynamoDelete, dynamoGet, dynamoPut
@docs dynamoQuery, dynamoResponse

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


port mmCreateWebhook : { id : String, topic : String, url : String } -> Cmd msg


port mmOnError : ({ id : String, error : Value } -> msg) -> Sub msg



-- DynamoDB API


port dynamoGet : ( String, Value ) -> Cmd msg


port dynamoPut : ( String, Value ) -> Cmd msg


port dynamoDelete : ( String, Value ) -> Cmd msg


port dynamoBatchGet : ( String, Value ) -> Cmd msg


port dynamoBatchWrite : ( String, Value ) -> Cmd msg


port dynamoQuery : ( String, Value ) -> Cmd msg


port dynamoResponse : (( String, Value ) -> msg) -> Sub msg
