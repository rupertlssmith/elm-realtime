module DB.SnapshotTable exposing
    ( Key
    , MetadataRecord
    , Operations
    , Record
    , encodeKey
    , operations
    )

import AWS.Dynamo as Dynamo exposing (DynamoApi, DynamoTypedApi, Error, Order(..), Ports, Put)
import Codec exposing (Codec)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Procedure.Program
import Time exposing (Posix)


type alias Key =
    { id : String
    , seq : Int
    }


type alias Record =
    { id : String
    , seq : Int
    , updatedAt : Posix
    , snapshot : Value
    }


type alias MetadataRecord =
    { id : String
    , seq : Int
    , updatedAt : Posix
    , lastId : Int
    }


type alias Operations msg =
    { put : Put Record -> (Result Error () -> msg) -> Cmd msg
    , findLatestSnapshot : String -> (Result Error (List Record) -> msg) -> Cmd msg
    }


operations :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> String
    ->
        { put : Put Record -> (Result Error () -> msg) -> Cmd msg
        , findLatestSnapshot : String -> (Result Error (List Record) -> msg) -> Cmd msg
        }
operations proc ports tableName =
    let
        typedApi =
            Dynamo.dynamoTypedApi
                encodeKey
                (Codec.encoder recordCodec)
                (Codec.decoder recordCodec)
                proc
                ports
    in
    { put = typedApi.put
    , findLatestSnapshot = \channel -> findLatestSnapshotQuery tableName channel |> typedApi.query
    }


findLatestSnapshotQuery tableName channel =
    let
        matchLatestSnapshot =
            Dynamo.partitionKeyEquals "id" channel
                |> Dynamo.orderResults Reverse
                |> Dynamo.limitResults 1
    in
    { tableName = tableName
    , match = matchLatestSnapshot
    }


recordCodec : Codec Record
recordCodec =
    Codec.object Record
        |> Codec.field "id" .id Codec.string
        |> Codec.field "seq" .seq Codec.int
        |> Codec.field "updatedAt" .updatedAt posixCodec
        |> Codec.field "snapshot" .snapshot Codec.value
        |> Codec.buildObject


encodeKey : Key -> Value
encodeKey key =
    Encode.object [ ( "id", Encode.string key.id ), ( "seq", Encode.int key.seq ) ]


posixCodec : Codec Posix
posixCodec =
    Codec.build
        (\timestamp -> Encode.int (Time.posixToMillis timestamp))
        (Decode.map Time.millisToPosix Decode.int)
