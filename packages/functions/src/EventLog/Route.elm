module EventLog.Route exposing
    ( Route(..)
    , routeParser
    )

import Url exposing (Url)
import Url.Parser as UP exposing ((</>), (<?>))


type Route
    = ChannelRoot
    | Channel String
    | ChannelJoin String


routeParser : Url -> Maybe Route
routeParser =
    UP.oneOf
        [ UP.map ChannelRoot (UP.s "channel")
        , UP.map Channel (UP.s "channel" </> UP.string)
        , UP.map ChannelJoin (UP.s "channel" </> UP.string </> UP.s "join")
        ]
        |> UP.parse
