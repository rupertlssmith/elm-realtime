module EventLog.Component exposing (..)

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

import Server.API exposing (ApiRoute)
import Serverless.Conn.Request as Request exposing (Method(..))
import Update2 as U2
import Url exposing (Url)
import Url.Parser as UP exposing ((</>), (<?>))


type alias Component a =
    { a
        | eventLog : Model
    }


setModel m x =
    { m | eventLog = x }



-- API Routing


type Route
    = V1


routeParser : Url -> Maybe Route
routeParser =
    UP.oneOf
        [ UP.map V1 (UP.s "v1")
        ]
        |> UP.map (Debug.log "route")
        |> UP.parse


processRoute : Protocol (Component a) msg model -> ApiRoute Route -> Component a -> ( Component a, Cmd msg )
processRoute protocol route model =
    case ( Request.method route.request, route.route ) |> Debug.log "processRoute" of
        ( GET, V1 ) ->
            U2.pure model

        _ ->
            U2.pure model



-- Side Effects


type alias Model =
    {}


type Msg
    = Noop


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    {}
        |> U2.pure
        |> Tuple.mapSecond (Cmd.map toMsg)


update : Protocol (Component a) msg model -> Msg -> Component a -> ( Component a, Cmd msg )
update protocol msg model =
    U2.pure model
