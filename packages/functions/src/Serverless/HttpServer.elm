module Serverless.HttpServer exposing
    ( Ports, Protocol
    , HttpServerApi, httpServerApi
    , HttpSessionKey, ApiRequest
    , Error(..), errorToDetails, errorToString
    )

{-| An API for running the server side of an HTTP and implementing an HTTP API.


# Ports and Protocol

@docs Ports, Protocol


# Packaged API and related data models

@docs HttpServerApi, httpServerApi
@docs HttpSessionKey, ApiRequest


# Error reporting

@docs Error, errorToDetails, errorToString

-}

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Serverless.Request as Request
import Serverless.Response as Response exposing (Response)
import Url exposing (Url)


type alias ApiRequest route =
    { route : route
    , request : Request.Request
    }


type HttpSessionKey
    = HttpSessionKey Value -- This actually holds the `callback` in an util.promisify()


type alias Ports msg =
    { request : ({ session : Value, req : Value } -> msg) -> Sub msg
    , response : { session : Value, res : Value } -> Cmd msg
    }


type alias Protocol msg route =
    { ports : Ports msg
    , parseRoute : Url -> Maybe route
    }


type alias HttpServerApi msg route =
    { request : (HttpSessionKey -> Result Error (ApiRequest route) -> msg) -> Sub msg
    , response : HttpSessionKey -> Response -> Cmd msg
    }


httpServerApi : Protocol msg route -> HttpServerApi msg route
httpServerApi protocol =
    { request = requestSub protocol
    , response = responseCmd protocol
    }


type Error
    = NoMatchingRoute String
    | InvalidRequestFormat Decode.Error


errorToString : Error -> String
errorToString error =
    case error of
        NoMatchingRoute url ->
            "No matching route for: " ++ url

        InvalidRequestFormat decodeError ->
            "Problem decoding the request: " ++ Decode.errorToString decodeError


errorToDetails : Error -> { message : String, details : Value }
errorToDetails error =
    case error of
        NoMatchingRoute url ->
            { message = "No matching route for: " ++ url
            , details = Encode.null
            }

        InvalidRequestFormat decodeError ->
            { message = "Problem decoding the request: " ++ Decode.errorToString decodeError
            , details = Encode.null
            }


requestSub :
    Protocol msg route
    -> (HttpSessionKey -> Result Error (ApiRequest route) -> msg)
    -> Sub msg
requestSub protocol requestFn =
    let
        fn { session, req } =
            decodeRequestAndRoute req protocol.parseRoute
                |> Result.map
                    (\( request, route ) ->
                        { request = request
                        , route = route
                        }
                    )
                |> requestFn (HttpSessionKey session)
    in
    Sub.map identity (protocol.ports.request fn)


decodeRequestAndRoute : Value -> (Url -> Maybe route) -> Result Error ( Request.Request, route )
decodeRequestAndRoute rawRequest parseRoute =
    Decode.decodeValue Request.decoder rawRequest
        |> Result.mapError InvalidRequestFormat
        |> Result.andThen
            (\req ->
                Request.url req
                    |> Url.fromString
                    |> Maybe.andThen parseRoute
                    |> (\maybeRoute ->
                            case maybeRoute of
                                Nothing ->
                                    Request.url req |> NoMatchingRoute |> Err

                                Just route ->
                                    Ok ( req, route )
                       )
            )


responseCmd : Protocol msg route -> HttpSessionKey -> Response -> Cmd msg
responseCmd protocol (HttpSessionKey session) response =
    protocol.ports.response { session = session, res = Response.encode response }
