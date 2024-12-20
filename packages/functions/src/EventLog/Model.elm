module EventLog.Model exposing
    ( Model(..)
    , ReadyState
    , StartState
    )

import Dict exposing (Dict)
import EventLog.Msg exposing (Msg)
import Json.Decode exposing (Value)
import Procedure.Program
import Random
import Realtime exposing (Snapshot)


type Model
    = ModelStart StartState
    | ModelReady ReadyState


type alias StartState =
    {}


type alias ReadyState =
    { seed : Random.Seed
    , procedure : Procedure.Program.Model Msg
    , cache : Dict String (Snapshot Value)
    }
