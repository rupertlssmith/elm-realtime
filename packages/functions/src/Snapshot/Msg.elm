module Snapshot.Msg exposing (Msg(..))

import HttpServer exposing (HttpSessionKey)
import Procedure.Program
import Random
import SqsLambda exposing (SqsEvent)


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | RandomSeed Random.Seed
    | SqsEvent HttpSessionKey (Result SqsLambda.Error SqsEvent)
