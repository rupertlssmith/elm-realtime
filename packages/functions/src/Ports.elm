port module Ports exposing
    ( requestPort, responsePort
    , mmOpen, mmClose
    , mmSubscribe, mmPublish, mmOnMessage
    , mmPushList, mmCreateWebhook
    , mmResponse, mmAsyncError
    , dynamoBatchGet, dynamoBatchWrite, dynamoDelete, dynamoGet, dynamoPut
    , dynamoQuery, dynamoResponse
    )

{-| Application ports


# AWS Lambda ports

@docs requestPort, responsePort


# Momento Cache

@docs mmOpen, mmClose
@docs mmSubscribe, mmPublish, mmOnMessage
@docs mmPushList, mmCreateWebhook
@docs mmResponse, mmAsyncError


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


port mmClose : { id : String, session : Value } -> Cmd msg


port mmSubscribe : { id : String, session : Value, topic : String } -> Cmd msg


port mmPublish : { id : String, session : Value, topic : String, payload : String } -> Cmd msg


port mmOnMessage : ({ id : String, session : Value, payload : String } -> msg) -> Sub msg


port mmPushList : { id : String, session : Value, list : String, payload : String } -> Cmd msg


port mmCreateWebhook : { id : String, session : Value, topic : String, url : String } -> Cmd msg


port mmResponse : ({ id : String, type_ : String, response : Value } -> msg) -> Sub msg


port mmAsyncError : ({ id : String, error : Value } -> msg) -> Sub msg



-- DynamoDB API


port dynamoGet : ( String, Value ) -> Cmd msg


port dynamoPut : ( String, Value ) -> Cmd msg


port dynamoDelete : ( String, Value ) -> Cmd msg


port dynamoBatchGet : ( String, Value ) -> Cmd msg


port dynamoBatchWrite : ( String, Value ) -> Cmd msg


port dynamoQuery : ( String, Value ) -> Cmd msg


port dynamoResponse : (( String, Value ) -> msg) -> Sub msg
