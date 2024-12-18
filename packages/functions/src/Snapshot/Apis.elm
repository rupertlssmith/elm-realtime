module Snapshot.Apis exposing
    ( channelTableApi
    , eventLogTableApi
    , eventLogTableMetadataApi
    , httpServerApi
    , momentoApi
    , snapshotTableApi
    , snapshotTableMetadataApi
    , sqsLambdaApi
    )

import AWS.Dynamo as Dynamo exposing (Error(..))
import DB.ChannelTable as ChannelTable
import DB.EventLogTable as EventLogTable
import DB.SnapshotTable as SnapshotTable
import HttpServer as HttpServer exposing (HttpSessionKey)
import Momento exposing (CacheItem, Error, MomentoSessionKey)
import Ports
import Snapshot.Msg exposing (Msg(..))
import SqsLambda


dynamoPorts : Dynamo.Ports Msg
dynamoPorts =
    { get = Ports.dynamoGet
    , put = Ports.dynamoPut
    , update = Ports.dynamoUpdate
    , writeTx = Ports.dynamoWriteTx
    , delete = Ports.dynamoDelete
    , batchGet = Ports.dynamoBatchGet
    , batchWrite = Ports.dynamoBatchWrite
    , scan = Ports.dynamoScan
    , query = Ports.dynamoQuery
    , response = Ports.dynamoResponse
    }


channelTableApi : Dynamo.DynamoTypedApi ChannelTable.Key ChannelTable.Record Msg
channelTableApi =
    ChannelTable.operations ProcedureMsg dynamoPorts


eventLogTableApi : Dynamo.DynamoTypedApi EventLogTable.Key EventLogTable.Record Msg
eventLogTableApi =
    EventLogTable.operations ProcedureMsg dynamoPorts


eventLogTableMetadataApi : Dynamo.DynamoTypedApi EventLogTable.Key EventLogTable.MetadataRecord Msg
eventLogTableMetadataApi =
    EventLogTable.metadataOperations ProcedureMsg dynamoPorts


snapshotTableApi : Dynamo.DynamoTypedApi SnapshotTable.Key SnapshotTable.Record Msg
snapshotTableApi =
    SnapshotTable.operations ProcedureMsg dynamoPorts


snapshotTableMetadataApi : Dynamo.DynamoTypedApi SnapshotTable.Key SnapshotTable.MetadataRecord Msg
snapshotTableMetadataApi =
    SnapshotTable.metadataOperations ProcedureMsg dynamoPorts


momentoApi : Momento.MomentoApi Msg
momentoApi =
    { open = Ports.mmOpen
    , close = Ports.mmClose
    , subscribe = Ports.mmSubscribe
    , publish = Ports.mmPublish
    , onMessage = Ports.mmOnMessage
    , pushList = Ports.mmPushList
    , popList = Ports.mmPopList
    , createWebhook = Ports.mmCreateWebhook
    , response = Ports.mmResponse
    , asyncError = Ports.mmAsyncError
    }
        |> Momento.momentoApi ProcedureMsg


httpServerApi : HttpServer.HttpServerApi Msg ()
httpServerApi =
    { ports =
        { request = Ports.requestPort
        , response = Ports.responsePort
        }
    , parseRoute = Just () |> always
    }
        |> HttpServer.httpServerApi


sqsLambdaApi : SqsLambda.SqsEventApi Msg
sqsLambdaApi =
    { sqsLambdaSubscribe = Ports.sqsLambdaSubscribe }
        |> SqsLambda.sqsEventApi
