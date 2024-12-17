module Snapshot.Msg exposing (Msg(..))

import Http.Response exposing (Response)
import HttpServer exposing (HttpSessionKey)
import Procedure.Program
import Random
import SqsLambda exposing (SqsEvent)


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | RandomSeed Random.Seed
    | HttpResponse HttpSessionKey (Result Response Response)
    | SqsEvent HttpSessionKey (Result SqsLambda.Error SqsEvent)
