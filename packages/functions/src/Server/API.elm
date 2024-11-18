module Server.API exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Ports
import Serverless.Conn.Body as Body
import Serverless.Conn.Request as Request
import Serverless.Conn.Response as Response
import Update2 as U2
import Url exposing (Url)


type alias Component a =
    { a
        | api : Model
    }


setModel m x =
    { m | api = x }


type Msg
    = Request ( String, Encode.Value, Encode.Value )


type alias Model =
    {}


type alias Ports =
    { request : (( String, Value, Value ) -> Msg) -> Sub Msg
    , response : ( String, Value, Value ) -> Cmd Msg
    }


type alias Protocol submodel msg model route =
    { toMsg : Msg -> msg
    , ports : Ports
    , parseRoute : Url -> Maybe route
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    {}
        |> U2.pure
        |> Tuple.mapSecond (Cmd.map toMsg)


subscriptions : Protocol (Component a) msg model route -> Model -> Sub msg
subscriptions protocol model =
    protocol.ports.request Request
        |> Sub.map protocol.toMsg


update : Protocol (Component a) msg model route -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.api

        _ =
            Debug.log "update" "called"
    in
    case msg of
        Request ( id, cb, rawRequest ) ->
            U2.pure model
                |> U2.andThen (decodeRequestAndRoute protocol rawRequest)
                |> U2.andThen (ok id cb)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate


decodeRequestAndRoute : Protocol (Component a) msg model route -> Value -> Model -> ( Model, Cmd Msg )
decodeRequestAndRoute protocol rawRequest model =
    case Decode.decodeValue Request.decoder rawRequest of
        Ok req ->
            case Request.url req |> Url.fromString |> Maybe.andThen protocol.parseRoute of
                Just route ->
                    let
                        _ =
                            Debug.log "decodeRequestAndRoute" route
                    in
                    U2.pure model

                Nothing ->
                    let
                        _ =
                            Debug.log "decodeRequestAndRoute" "no route matched"
                    in
                    U2.pure model

        Err err ->
            let
                _ =
                    Debug.log "decodeRequestAndRoute" err
            in
            U2.pure model


ok id cb model =
    let
        response =
            Response.init
                |> Response.setBody (Body.text "Hello from Elm, it works!")
                |> Response.encode
    in
    ( model, Ports.responsePort ( id, cb, response ) )
