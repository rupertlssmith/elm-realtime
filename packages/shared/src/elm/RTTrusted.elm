module RTTrusted exposing (program)

{-| RTTrusted is an Elm program type for implementing trusted realtime nodes.

In an elm-realtime system, there can be a trusted node that is also written in Elm.

The trusted node can examine and operate on any realtime events, that pass through it.

The trusted node is responsible for generating model snapshots from event logs.

-}

import Realtime exposing (RTMessage, Snapshot)


type Error
    = Error


program :
    -- These should be subscriptions and commands.
    { init : flags -> ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    }
    -> Platform.Program flags model msg
program =
    Platform.worker



-- Do the Value pass through thing on this. Will be wrapping this in some NodeJS that will invoke it
-- with events and compaction requests, and wait for it to respond.
-- Sub: new message, new snapshot request
-- Cmd: publish messages, new snapshot


compact : List RTMessage -> Snapshot a -> Snapshot a


stream : Snapshot a -> RTMessage -> Result Error (List RTMessage)
