port module Ports exposing
    ( requestPort, responsePort
    , sqsLambdaSubscribe
    , mmOpen, mmClose
    , mmSubscribe, mmPublish, mmOnMessage
    , mmResponse, mmAsyncError
    , mmCreateWebhook
    , mmPushList, mmPopList
    , dynamoBatchGet, dynamoBatchWrite, dynamoDelete, dynamoGet, dynamoPut, dynamoUpdate
    , dynamoScan, dynamoQuery, dynamoResponse, dynamoWriteTx
    )

{-| Application ports


# AWS Lambda ports

@docs requestPort, responsePort
@docs sqsLambdaSubscribe


# Momento Cache

@docs mmOpen, mmClose
@docs mmSubscribe, mmPublish, mmOnMessage
@docs mmResponse, mmAsyncError
@docs mmCreateWebhook
@docs mmPushList, mmPopList


# AWS Dynamo DB

@docs dynamoBatchGet, dynamoBatchWrite, dynamoDelete, dynamoGet, dynamoPut, dynamoUpdate
@docs dynamoScan, dynamoQuery, dynamoResponse, dynamoWriteTx

-}

import Json.Encode exposing (Value)



-- AWS Lambda ports


port requestPort : ({ session : Value, req : Value } -> msg) -> Sub msg


port responsePort : { session : Value, res : Value } -> Cmd msg


port sqsLambdaSubscribe : ({ session : Value, req : Value } -> msg) -> Sub msg



-- Momento API


port mmOpen : { id : String, cache : String, apiKey : String } -> Cmd msg


port mmClose : { id : String, session : Value } -> Cmd msg


port mmSubscribe : { id : String, session : Value, topic : String } -> Cmd msg


port mmPublish : { id : String, session : Value, topic : String, payload : Value } -> Cmd msg


port mmOnMessage : ({ id : String, session : Value, payload : Value } -> msg) -> Sub msg


port mmPushList : { id : String, session : Value, list : String, payload : Value } -> Cmd msg


port mmPopList : { id : String, session : Value, list : String } -> Cmd msg


port mmCreateWebhook : { id : String, session : Value, name : String, topic : String, url : String } -> Cmd msg


port mmResponse : ({ id : String, type_ : String, response : Value } -> msg) -> Sub msg


port mmAsyncError : ({ id : String, error : Value } -> msg) -> Sub msg



-- DynamoDB API


port dynamoGet : { id : String, req : Value } -> Cmd msg


port dynamoPut : { id : String, req : Value } -> Cmd msg


port dynamoUpdate : { id : String, req : Value } -> Cmd msg


port dynamoWriteTx : { id : String, req : Value } -> Cmd msg


port dynamoDelete : { id : String, req : Value } -> Cmd msg


port dynamoBatchGet : { id : String, req : Value } -> Cmd msg


port dynamoBatchWrite : { id : String, req : Value } -> Cmd msg


port dynamoScan : { id : String, req : Value } -> Cmd msg


port dynamoQuery : { id : String, req : Value } -> Cmd msg


port dynamoResponse : ({ id : String, res : Value } -> msg) -> Sub msg
