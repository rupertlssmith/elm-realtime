module EventLog.Msg exposing (Msg(..))

import EventLog.Route exposing (Route)
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Procedure.Program
import Random
import Serverless.HttpServer as HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Serverless.Response exposing (Response)


type Msg
    = ProcedureMsg (Procedure.Program.Msg Msg)
    | RandomSeed Random.Seed
    | HttpRequest HttpSessionKey (Result HttpServer.Error (ApiRequest Route))
    | HttpResponse HttpSessionKey (Result Response Response)
    | MomentoError Momento.Error
