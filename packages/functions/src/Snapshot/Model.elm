module Snapshot.Model exposing
    ( Model(..)
    , ReadyState
    , StartState
    )

import Snapshot.Msg exposing (Msg)
import Procedure.Program
import Random


type Model
    = ModelStart StartState
    | ModelReady ReadyState


type alias StartState =
    {}


type alias ReadyState =
    { seed : Random.Seed
    , procedure : Procedure.Program.Model Msg
    }
