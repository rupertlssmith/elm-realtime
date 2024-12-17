module EventLog.Msg exposing (Msg(..))

import EventLog.Route exposing (Route)
import Http.Response exposing (Response)
import HttpServer as HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Procedure.Program
import Random
import SqsLambda exposing (SqsEvent)


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | RandomSeed Random.Seed
    | HttpRequest HttpSessionKey (Result HttpServer.Error (ApiRequest Route))
    | HttpResponse HttpSessionKey (Result Response Response)
    | MomentoError Momento.Error
    | SqsEvent HttpSessionKey (Result SqsLambda.Error SqsEvent)
