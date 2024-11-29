module DB.EventLogTable exposing
    ( Key
    , Record
    , operations
    )

import AWS.Dynamo as Dynamo exposing (DynamoApi, DynamoTypedApi, Ports)
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
    , event : Value
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
        |> Codec.field "seq" .seq Codec.int
        |> Codec.field "updatedAt" .updatedAt posixCodec
        |> Codec.field "event" .event Codec.value
        |> Codec.buildObject


encodeKey : Key -> Value
encodeKey key =
    Encode.object [ ( "id", Encode.string key.id ), ( "seq", Encode.int key.seq ) ]


posixCodec : Codec Posix
posixCodec =
    Codec.build
        (\timestamp -> Encode.int (Time.posixToMillis timestamp))
        (Decode.map Time.millisToPosix Decode.int)
