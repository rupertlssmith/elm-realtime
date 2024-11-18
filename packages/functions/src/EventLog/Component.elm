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

import Url exposing (Url)
import Url.Builder
import Url.Parser as UP exposing ((</>), (<?>))
import Url.Parser.Query as Query


type Route
    = V1


routeParser : Url -> Maybe Route
routeParser =
    UP.oneOf
        [ UP.map V1 (UP.s "v1")
        ]
        |> UP.map (Debug.log "route")
        |> UP.parse
