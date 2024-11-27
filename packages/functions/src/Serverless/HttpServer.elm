module Serverless.HttpServer exposing
    ( ApiRequest
    , Error(..)
    , HttpServerApi
    , HttpSessionKey
    , Ports
    , Protocol
    , errorToString
    , httpServerApi
    )

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Serverless.Conn.Request as Request
import Serverless.Conn.Response as Response exposing (Response)
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
    = Error String


errorToString : Error -> String
errorToString (Error message) =
    message


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
                |> Result.mapError Error
                |> requestFn (HttpSessionKey session)
    in
    Sub.map identity (protocol.ports.request fn)


decodeRequestAndRoute : Value -> (Url -> Maybe route) -> Result String ( Request.Request, route )
decodeRequestAndRoute rawRequest parseRoute =
    Decode.decodeValue Request.decoder rawRequest
        |> Result.mapError Decode.errorToString
        |> Result.andThen
            (\req ->
                Request.url req
                    |> Url.fromString
                    |> Maybe.andThen parseRoute
                    |> (\maybeRoute ->
                            case maybeRoute of
                                Nothing ->
                                    Err "No matching route."

                                Just route ->
                                    Ok ( req, route )
                       )
            )


responseCmd : Protocol msg route -> HttpSessionKey -> Response -> Cmd msg
responseCmd protocol (HttpSessionKey session) response =
    protocol.ports.response { session = session, res = Response.encode response }
