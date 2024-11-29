module DB.ChannelTable exposing
    ( Key
    , Record
    , operations
    , recordCodec
    )

import AWS.Dynamo as Dynamo exposing (DynamoApi, DynamoTypedApi, Ports)
import Codec exposing (Codec)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Procedure.Program
import Time exposing (Posix)


type alias Key =
    { id : String
    }


type alias Record =
    { id : String
    , updatedAt : Posix
    , modelTopic : String
    , saveTopic : String
    , saveList : String
    , webhook : String
    }


operations : (Procedure.Program.Msg msg -> msg) -> Ports msg -> DynamoTypedApi Key Record msg
operations =
    Dynamo.dynamoTypedApi
        encodeKey
        (Codec.encoder recordCodec)
        (Codec.decoder recordCodec)


recordCodec : Codec Record
recordCodec =
    Codec.object Record
        |> Codec.field "id" .id Codec.string
        |> Codec.field "updatedAt" .updatedAt posixCodec
        |> Codec.field "modelTopic" .modelTopic Codec.string
        |> Codec.field "saveTopic" .saveTopic Codec.string
        |> Codec.field "saveList" .saveList Codec.string
        |> Codec.field "webhook" .webhook Codec.string
        |> Codec.buildObject


encodeKey : Key -> Value
encodeKey key =
    Encode.object [ ( "id", Encode.string key.id ) ]


posixCodec : Codec Posix
posixCodec =
    Codec.build
        (\timestamp -> Encode.int (Time.posixToMillis timestamp))
        (Decode.map Time.millisToPosix Decode.int)
