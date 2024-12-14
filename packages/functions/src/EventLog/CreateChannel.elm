module EventLog.CreateChannel exposing (createChannel)

import AWS.Dynamo as Dynamo exposing (Error(..))
import Codec
import DB.ChannelTable as ChannelTable
import DB.EventLogTable
import EventLog.Apis as Apis
import EventLog.ErrorFormat as ErrorFormat exposing (ErrorFormat)
import EventLog.Model exposing (Model(..), ReadyState)
import EventLog.Msg exposing (Msg(..))
import EventLog.Names as Names
import EventLog.OpenMomentoCache as OpenMomentoCache
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Procedure
import Random
import Serverless.Response as Response exposing (Response)
import Time
import Update2 as U2


type alias CreateChannel a =
    { a
        | momentoApiKey : String
        , channelApiUrl : String
        , channelTable : String
        , eventLogTable : String
        , eventLog : Model
    }


setModel : CreateChannel a -> Model -> CreateChannel a
setModel m x =
    { m | eventLog = x }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


{-| Channel creation:

    * Create the cache or confirm it already exists.
    * Create a webhook on the save topic.
    * Create the meta-data record for the channel in the events table.
    * Record the channel information in the channels table.
    * Return a confirmation that everything has been set up.

-}
createChannel : HttpSessionKey -> ReadyState -> CreateChannel a -> ( CreateChannel a, Cmd Msg )
createChannel session state component =
    let
        ( channelName, nextSeed ) =
            Random.step Names.nameGenerator state.seed

        procedure : Procedure.Procedure Response Response Msg
        procedure =
            Procedure.provide channelName
                |> Procedure.andThen (OpenMomentoCache.openMomentoCache component)
                |> Procedure.andThen (setupChannelWebhook component channelName)
                |> Procedure.andThen (recordEventsLogMetaData component channelName)
                |> Procedure.andThen (recordChannel component channelName)
                |> Procedure.mapError (ErrorFormat.encodeErrorFormat >> Response.err500json)
                |> Procedure.map (Codec.encoder ChannelTable.recordCodec >> Response.ok200json)
    in
    ( { seed = nextSeed
      , procedure = state.procedure
      }
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)


setupChannelWebhook :
    CreateChannel a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat MomentoSessionKey Msg
setupChannelWebhook component channelName sessionKey =
    Apis.momentoApi.webhook
        sessionKey
        { name = Names.webhookName channelName
        , topic = Names.notifyTopicName channelName
        , url = component.channelApiUrl ++ "/v1/channel/" ++ channelName
        }
        |> Procedure.fetchResult
        |> Procedure.mapError Momento.errorToDetails
        |> Procedure.map (always sessionKey)


recordEventsLogMetaData :
    CreateChannel a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat MomentoSessionKey Msg
recordEventsLogMetaData component channelName sessionKey =
    Procedure.fromTask Time.now
        |> Procedure.andThen
            (\timestamp ->
                let
                    metadataRecord =
                        { id = Names.metadataKeyName channelName
                        , seq = 0
                        , updatedAt = timestamp
                        , lastId = 0
                        }
                in
                Apis.eventLogTableMetadataApi.put
                    { tableName = component.eventLogTable
                    , item = metadataRecord
                    }
                    |> Procedure.fetchResult
                    |> Procedure.map (always sessionKey)
                    |> Procedure.mapError Dynamo.errorToDetails
            )


recordChannel :
    CreateChannel a
    -> String
    -> MomentoSessionKey
    -> Procedure.Procedure ErrorFormat ChannelTable.Record Msg
recordChannel component channelName sessionKey =
    Procedure.fromTask Time.now
        |> Procedure.andThen
            (\timestamp ->
                let
                    channelRecord =
                        { id = channelName
                        , updatedAt = timestamp
                        , modelTopic = Names.modelTopicName channelName
                        , saveTopic = Names.notifyTopicName channelName
                        , saveList = Names.saveListName channelName
                        , webhook = Names.webhookName channelName
                        }
                in
                Apis.channelTableApi.put
                    { tableName = component.channelTable
                    , item = channelRecord
                    }
                    |> Procedure.fetchResult
                    |> Procedure.map (always channelRecord)
                    |> Procedure.mapError Dynamo.errorToDetails
            )
