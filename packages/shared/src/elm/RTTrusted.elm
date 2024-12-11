module RTTrusted exposing (..)

{-| RTTrusted is an Elm program type for implementing trusted realtime nodes.

In an elm-realtime system, there can be a trusted node that is also written in Elm.

The trusted node can examine and operate on any realtime events, that pass through it.

The trusted node is responsible for generating model snapshots from event logs.

-}

import Realtime exposing (RTMessage)


type Snapshot
    = Snapshot


type Error
    = Error


program :
    -- Should these be subscriptions?
    { compact : List RTMessage -> Snapshot -> Snapshot
    , stream : Snapshot -> RTMessage -> Result Error (List RTMessage)
    }
    -> Platform.Program flags model msg
program =
    Debug.todo ""
