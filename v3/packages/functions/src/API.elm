port module API exposing (main)

import Json.Encode as Encode exposing (Value)
import Ports
import Serverless.Conn.Body as Body
import Serverless.Conn.Response as Response


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
type Msg
    = Request ( String, Encode.Value, Encode.Value )


type alias Config =
    { momentoApiKey : String
    }


type alias Model =
    { momentoApiKey : String }


main : Platform.Program Config Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


init : Config -> ( Model, Cmd Msg )
init flags =
    ( { momentoApiKey = flags.momentoApiKey }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.requestPort Request


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
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
