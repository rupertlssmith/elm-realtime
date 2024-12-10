module EventLog.OpenMomentoCache exposing (openMomentoCache)

import EventLog.Apis as Apis
import EventLog.ErrorFormat exposing (ErrorFormat)
import EventLog.Msg exposing (Msg(..))
import EventLog.Names as Names
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Procedure


type alias OpenMomentoCache a =
    { a
        | momentoApiKey : String
    }


{-| Opens the named Momento cache and obtains a SessionKey to talk to it.
-}
openMomentoCache :
    OpenMomentoCache a
    -> String
    -> Procedure.Procedure ErrorFormat MomentoSessionKey Msg
openMomentoCache component channelName =
    Apis.momentoApi.open
        { apiKey = component.momentoApiKey
        , cache = Names.cacheName channelName
        }
        |> Procedure.fetchResult
        |> Procedure.mapError Momento.errorToDetails
