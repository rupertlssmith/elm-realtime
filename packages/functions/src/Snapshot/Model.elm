module Snapshot.Model exposing
    ( Model(..)
    , ReadyState
    , StartState
    )

import Dict exposing (Dict)
import Json.Encode exposing (Value)
import Procedure.Program
import Random
import Realtime exposing (Snapshot)
import Snapshot.Msg exposing (Msg)


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
