module EventLog.Model exposing
    ( Model(..)
    , ReadyState
    , StartState
    )

import EventLog.Msg exposing (Msg)
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
