module Server.API exposing (..)

{-| API for managing realtime channels.

Channel creation:

    * Create the cache or confirm it already exists.
    * Create a webhook on the save topic.
    * Create a dynamodb table for the persisted events.
    * Return a confirmation that everything has been set up.

Channel save:

    * Obtain a connection to the cache.
    * Read the saved events from the cache list.
    * Save the events to the dynamodb event log.
    * Remove the saved events from the cache list.
    * Publish the saved event to the model topic.

-}

import Json.Encode as Encode exposing (Value)
import Ports
import Serverless.Conn.Body as Body
import Serverless.Conn.Response as Response
import Update2 as U2


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


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , ports : Ports
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    {}
        |> U2.pure
        |> Tuple.mapSecond (Cmd.map toMsg)


subscriptions : Protocol (Component a) msg model -> Model -> Sub msg
subscriptions protocol model =
    protocol.ports.request Request
        |> Sub.map protocol.toMsg


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.api

        _ =
            Debug.log "update" "called"
    in
    case msg of
        Request ( id, cb, req ) ->
            let
                response =
                    Response.init
                        |> Response.setBody (Body.text "Hello from Elm, it works!")
                        |> Response.encode
            in
            ( model, Ports.responsePort ( id, cb, response ) )
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate
