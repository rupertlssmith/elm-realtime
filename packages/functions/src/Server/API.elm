module Server.API exposing (ApiRoute, Model, Msg(..), Ports, Protocol, checkAndForwardRoute, decodeRequestAndRoute, err500, init, ok200, subscriptions, update)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Ports
import Serverless.Conn.Body as Body
import Serverless.Conn.Request as Request
import Serverless.Conn.Response as Response
import Update2 as U2
import Url exposing (Url)


type Msg
    = Request { session : Value, req : Value }


type alias Model =
    {}


type alias Ports msg =
    { request : ({ session : Value, req : Value } -> msg) -> Sub msg
    , response : { session : Value, res : Value } -> Cmd msg
    }


type alias ApiRoute route =
    { route : route
    , request : Request.Request
    }


type alias Protocol submodel msg model route =
    { toMsg : Msg -> msg
    , ports : Ports Msg
    , parseRoute : Url -> Maybe route
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onApiRoute : ApiRoute route -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    {}
        |> U2.pure
        |> Tuple.mapSecond (Cmd.map toMsg)


subscriptions : Protocol Model msg model route -> Model -> Sub msg
subscriptions protocol _ =
    protocol.ports.request Request
        |> Sub.map protocol.toMsg


update : Protocol Model msg model route -> Msg -> Model -> ( model, Cmd msg )
update protocol msg model =
    let
        _ =
            Debug.log "update" "called"
    in
    case msg of
        Request { session, req } ->
            U2.pure model
                |> U2.andMap (checkAndForwardRoute protocol session req)


checkAndForwardRoute : Protocol Model msg model route -> Value -> Value -> Model -> ( model, Cmd msg )
checkAndForwardRoute protocol session rawRequest model =
    case decodeRequestAndRoute rawRequest protocol.parseRoute of
        Ok ( req, route ) ->
            let
                _ =
                    Debug.log "decodeRequestAndRoute" route
            in
            U2.pure model
                |> U2.andThen (ok200 session)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onApiRoute
                    { route = route
                    , request = req
                    }

        Err err ->
            let
                _ =
                    Debug.log "decodeRequestAndRoute" err
            in
            U2.pure model
                |> U2.andThen (err500 session err)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate


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


ok200 : Value -> Model -> ( Model, Cmd msg )
ok200 session model =
    let
        response =
            Response.init
                |> Response.setBody (Body.text "Hello from Elm, it works!")
                |> Response.encode
    in
    ( model, Ports.responsePort { session = session, res = response } )


err500 : Value -> String -> Model -> ( Model, Cmd msg )
err500 session err model =
    let
        response =
            Response.init
                |> Response.setBody (Body.text err)
                |> Response.setStatus 500
                |> Response.encode
    in
    ( model, Ports.responsePort { session = session, res = response } )
