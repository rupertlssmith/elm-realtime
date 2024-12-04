module AWS.Dynamo exposing
    ( Ports
    , dynamoApi, DynamoApi
    , dynamoTypedApi, DynamoTypedApi
    , Put
    , Get
    , Delete
    , Match, Order(..), partitionKeyEquals, limitResults, orderResults
    , rangeKeyEquals, rangeKeyLessThan, rangeKeyLessThanOrEqual, rangeKeyGreaterThan
    , rangeKeyGreaterThanOrEqual, rangeKeyBetween
    , int, string
    , Error, errorToString, errorToDetails
    )

{-| A wrapper around the AWS DynamoDB Document API.


# Ports

@docs Ports


# Packaged APIs

@docs dynamoApi, DynamoApi
@docs dynamoTypedApi, DynamoTypedApi


# Read and Write Operations

@docs Put
@docs Get
@docs Delete
@docs BatchPut
@docs BatchGet


# Database Queries

@docs Match, Order, partitionKeyEquals, limitResults, orderResults
@docs rangeKeyEquals, rangeKeyLessThan, rangeKeyLessThanOrEqual, rangeKeyGreaterThan
@docs rangeKeyGreaterThanOrEqual, rangeKeyBetween
@docs int, string


# Error reporting

@docs Error, errorToString, errorToDetails

-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra
import Maybe.Extra
import Procedure
import Procedure.Channel as Channel
import Procedure.Program
import Result.Extra


type alias Ports msg =
    { get : { id : String, req : Value } -> Cmd msg
    , put : { id : String, req : Value } -> Cmd msg
    , update : { id : String, req : Value } -> Cmd msg
    , delete : { id : String, req : Value } -> Cmd msg
    , batchGet : { id : String, req : Value } -> Cmd msg
    , batchWrite : { id : String, req : Value } -> Cmd msg
    , scan : { id : String, req : Value } -> Cmd msg
    , query : { id : String, req : Value } -> Cmd msg
    , response : ({ id : String, res : Value } -> msg) -> Sub msg
    }


type alias DynamoApi msg =
    { get : Get Value -> (Result Error (Maybe Value) -> msg) -> Cmd msg
    , put : Put Value -> (Result Error () -> msg) -> Cmd msg
    , delete : Delete Value -> (Result Error () -> msg) -> Cmd msg
    , batchGet : BatchGet Value -> (Result Error (List Value) -> msg) -> Cmd msg
    , batchPut : BatchPut Value -> (Result Error () -> msg) -> Cmd msg
    , scan : Scan -> (Result Error (List Value) -> msg) -> Cmd msg
    , query : Query -> (Result Error (List Value) -> msg) -> Cmd msg
    , queryIndex : QueryIndex -> (Result Error (List Value) -> msg) -> Cmd msg
    }


type alias DynamoTypedApi k v msg =
    { get : Get k -> (Result Error (Maybe v) -> msg) -> Cmd msg
    , put : Put v -> (Result Error () -> msg) -> Cmd msg
    , delete : Delete k -> (Result Error () -> msg) -> Cmd msg
    , batchGet : BatchGet k -> (Result Error (List v) -> msg) -> Cmd msg
    , batchPut : BatchPut v -> (Result Error () -> msg) -> Cmd msg
    , scan : Scan -> (Result Error (List v) -> msg) -> Cmd msg
    , query : Query -> (Result Error (List v) -> msg) -> Cmd msg
    , queryIndex : QueryIndex -> (Result Error (List v) -> msg) -> Cmd msg
    }


dynamoApi : (Procedure.Program.Msg msg -> msg) -> Ports msg -> DynamoApi msg
dynamoApi pt ports =
    { get = get pt ports identity Decode.value
    , put = put pt ports identity
    , delete = delete pt ports identity
    , batchGet = batchGet pt ports identity Decode.value
    , batchPut = batchPut pt ports identity
    , scan = scan pt ports Decode.value
    , query = query pt ports Decode.value
    , queryIndex = queryIndex pt ports Decode.value
    }


dynamoTypedApi :
    (k -> Value)
    -> (v -> Value)
    -> Decoder v
    -> (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> DynamoTypedApi k v msg
dynamoTypedApi keyEncoder valEncoder decoder pt ports =
    { get = get pt ports keyEncoder decoder
    , put = put pt ports valEncoder
    , delete = delete pt ports keyEncoder
    , batchGet = batchGet pt ports keyEncoder decoder
    , batchPut = batchPut pt ports valEncoder
    , scan = scan pt ports decoder
    , query = query pt ports decoder
    , queryIndex = queryIndex pt ports decoder
    }



-- Database operations


type Error
    = Error { message : String, details : Value }
    | DecodeError Decode.Error


errorToString : Error -> String
errorToString error =
    case error of
        Error { message } ->
            "AWS.Dynamo: " ++ message

        DecodeError err ->
            "AWS.Dynamo: " ++ Decode.errorToString err


errorToDetails : Error -> { message : String, details : Value }
errorToDetails error =
    case error of
        Error { message, details } ->
            { message = message
            , details = details
            }

        DecodeError err ->
            { message = Decode.errorToString err
            , details = Encode.null
            }


errorDecoder : Decoder (Result Error a)
errorDecoder =
    Decode.succeed
        (\message details ->
            { message = message
            , details = details
            }
        )
        |> DE.andMap (Decode.field "message" Decode.string)
        |> DE.andMap (Decode.field "details" Decode.value)
        |> Decode.map Error
        |> Decode.map Err



---- Put a document in DynamoDB


type alias Put v =
    { tableName : String
    , item : v
    }


put :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> (v -> Value)
    -> Put v
    -> (Result Error () -> msg)
    -> Cmd msg
put pt ports encoder putProps dt =
    Channel.open (\key -> ports.put { id = key, req = putEncoder encoder putProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> putResponseDecoder res |> dt)


putEncoder : (v -> Value) -> Put v -> Value
putEncoder encoder putOp =
    Encode.object
        [ ( "TableName", Encode.string putOp.tableName )
        , ( "Item", encoder putOp.item )
        ]


putResponseDecoder : Value -> Result Error ()
putResponseDecoder val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Ok" ->
                                Decode.succeed (Ok ())

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge



---- Update a document in DynamoDB


type alias Update k =
    { tableName : String
    , key : k
    , updateExpression : String
    , conditionExpression : Maybe String
    , expressionAttributeNames : Dict String String
    , expressionAttributeValues : Dict String AttributeValue
    , returnConsumedCapacity : Maybe ReturnConsumedCapacity
    , returnItemCollectionMetrics : Maybe ReturnItemCollectionMetrics
    , returnValues : Maybe ReturnValues
    , returnValuesOnConditionCheckFailure : Maybe ReturnValuesOnConditionCheckFailure
    }


type ReturnConsumedCapacity
    = CapacityIndexes
    | CapacityTotal


type ReturnItemCollectionMetrics
    = MetricsSize


type ReturnValues
    = ReturnValuesAllOld
    | ReturnValuesUpdatedOld
    | ReturnValuesAllNew
    | ReturnValuesUpdatedNew


type ReturnValuesOnConditionCheckFailure
    = CheckFailAllOld


update :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> (k -> Value)
    -> Decoder v
    -> Update k
    -> (Result Error (Maybe v) -> msg)
    -> Cmd msg
update pt ports encoder decoder updateProps dt =
    Channel.open (\key -> ports.put { id = key, req = updateEncoder encoder updateProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> getResponseDecoder decoder res |> dt)


updateEncoder : (k -> Value) -> Update k -> Value
updateEncoder encoder putOp =
    Encode.object
        [ ( "TableName", Encode.string putOp.tableName )
        , ( "Key", encoder putOp.key )
        , ( "UpdateExpression", Encode.string putOp.updateExpression )
        , ( "ConditionExpression", Json.Encode.Extra.maybe Encode.string putOp.conditionExpression )
        , ( "ExpressionAttributeNames", Encode.dict identity Encode.string putOp.expressionAttributeNames )
        , ( "ExpressionAttributeValues", Encode.dict identity encodeAttr putOp.expressionAttributeValues )
        , ( "ReturnConsumedCapacity"
          , Json.Encode.Extra.maybe encodeReturnConsumedCapacity putOp.returnConsumedCapacity
          )
        , ( "ReturnItemCollectionMetrics"
          , Json.Encode.Extra.maybe encodeReturnItemCollectionMetrics putOp.returnItemCollectionMetrics
          )
        , ( "ReturnValues", Json.Encode.Extra.maybe encodeReturnValues putOp.returnValues )
        , ( "ReturnValuesOnConditionCheckFailure"
          , Json.Encode.Extra.maybe encodeReturnValuesOnConditionCheckFailure putOp.returnValuesOnConditionCheckFailure
          )
        ]


encodeReturnConsumedCapacity : ReturnConsumedCapacity -> Value
encodeReturnConsumedCapacity arg =
    case arg of
        CapacityIndexes ->
            Encode.string "INDEXES"

        CapacityTotal ->
            Encode.string "TOTAL"


encodeReturnItemCollectionMetrics : ReturnItemCollectionMetrics -> Value
encodeReturnItemCollectionMetrics arg =
    case arg of
        MetricsSize ->
            Encode.string "SIZE"


encodeReturnValues : ReturnValues -> Value
encodeReturnValues arg =
    case arg of
        ReturnValuesAllOld ->
            Encode.string "ALL_OLD"

        ReturnValuesUpdatedOld ->
            Encode.string "UPDATED_OLD"

        ReturnValuesAllNew ->
            Encode.string "ALL_NEW"

        ReturnValuesUpdatedNew ->
            Encode.string "UPDATED_NEW"


encodeReturnValuesOnConditionCheckFailure : ReturnValuesOnConditionCheckFailure -> Value
encodeReturnValuesOnConditionCheckFailure arg =
    case arg of
        CheckFailAllOld ->
            Encode.string "ALL_OLD"


updateResponseDecoder : Value -> Result Error ()
updateResponseDecoder val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Ok" ->
                                Decode.succeed (Ok ())

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge



---- Get a document from DynamoDB


type alias Get k =
    { tableName : String
    , key : k
    }


get :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> (k -> Value)
    -> Decoder v
    -> Get k
    -> (Result Error (Maybe v) -> msg)
    -> Cmd msg
get pt ports encoder decoder getProps dt =
    Channel.open (\key -> ports.get { id = key, req = getEncoder encoder getProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> getResponseDecoder decoder res |> dt)


getEncoder : (v -> Value) -> Get v -> Value
getEncoder encoder getOp =
    Encode.object
        [ ( "TableName", Encode.string getOp.tableName )
        , ( "Key", encoder getOp.key )
        ]


getResponseDecoder : Decoder v -> Value -> Result Error (Maybe v)
getResponseDecoder valDecoder val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Item" ->
                                Decode.at [ "item", "Item" ] valDecoder
                                    |> Decode.map (Just >> Ok)

                            "ItemNotFound" ->
                                Decode.succeed (Ok Nothing)

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge



---- Delete


type alias Delete k =
    { tableName : String
    , key : k
    }


delete :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> (k -> Value)
    -> Delete k
    -> (Result Error () -> msg)
    -> Cmd msg
delete pt ports encoder deleteProps dt =
    Channel.open (\key -> ports.delete { id = key, req = deleteEncoder encoder deleteProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> deleteResponseDecoder res |> dt)


deleteEncoder : (k -> Value) -> Delete k -> Value
deleteEncoder encoder deleteOp =
    Encode.object
        [ ( "TableName", Encode.string deleteOp.tableName )
        , ( "Key", encoder deleteOp.key )
        ]


deleteResponseDecoder : Value -> Result Error ()
deleteResponseDecoder val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Ok" ->
                                Decode.succeed (Ok ())

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge



---- Batch Put


type alias BatchPut v =
    { tableName : String
    , items : List v
    }


batchPut :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> (v -> Value)
    -> BatchPut v
    -> (Result Error () -> msg)
    -> Cmd msg
batchPut pt ports encoder batchPutProps dt =
    batchPutInner ports encoder batchPutProps.tableName batchPutProps.items
        |> Procedure.run pt (\( _, res ) -> dt res)


batchPutInner :
    Ports msg
    -> (v -> Value)
    -> String
    -> List v
    -> Procedure.Procedure e ( String, Result Error () ) msg
batchPutInner ports encoder table vals =
    let
        firstBatch =
            List.take 25 vals

        remainder =
            List.drop 25 vals
    in
    Channel.open
        (\key ->
            ports.batchWrite
                { id = key
                , req = batchPutEncoder encoder { tableName = table, items = firstBatch }
                }
        )
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.andThen
            (\{ id, res } ->
                case batchPutResponseDecoder res of
                    Ok () ->
                        case remainder of
                            [] ->
                                Procedure.provide ( id, Ok () )

                            moreItems ->
                                batchPutInner ports encoder table moreItems

                    Err err ->
                        Procedure.provide ( id, Err err )
            )


batchPutEncoder : (v -> Value) -> BatchPut v -> Value
batchPutEncoder encoder putOp =
    let
        encodeItem item =
            Encode.object
                [ ( "PutRequest"
                  , Encode.object
                        [ ( "Item", encoder item ) ]
                  )
                ]
    in
    Encode.object
        [ ( "RequestItems"
          , Encode.object
                [ ( putOp.tableName
                  , Encode.list encodeItem putOp.items
                  )
                ]
          )
        ]


batchPutResponseDecoder : Value -> Result Error ()
batchPutResponseDecoder val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Ok" ->
                                Decode.succeed (Ok ())

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge



---- Batch Get


type alias BatchGet k =
    { tableName : String
    , keys : List k
    }


batchGet :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> (k -> Value)
    -> Decoder v
    -> BatchGet k
    -> (Result Error (List v) -> msg)
    -> Cmd msg
batchGet pt ports encoder decoder batchGetProps dt =
    Channel.open
        (\key ->
            ports.batchWrite
                { id = key
                , req =
                    batchGetEncoder encoder
                        { tableName = batchGetProps.tableName
                        , keys = batchGetProps.keys
                        }
                }
        )
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> batchGetResponseDecoder decoder batchGetProps.tableName res |> dt)


batchGetEncoder : (k -> Value) -> BatchGet k -> Value
batchGetEncoder encoder getOp =
    Encode.object
        [ ( "RequestItems"
          , Encode.object
                [ ( getOp.tableName
                  , Encode.object
                        [ ( "Keys", Encode.list encoder getOp.keys ) ]
                  )
                ]
          )
        ]


batchGetResponseDecoder : Decoder v -> String -> Value -> Result Error (List v)
batchGetResponseDecoder valDecoder tableName val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Item" ->
                                Decode.at [ "item", "Responses", tableName ] (Decode.list valDecoder)
                                    |> Decode.map Ok

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge



---- Scans


type alias Scan =
    { tableName : String
    , exclusiveStartKey : Maybe Value
    }


scan :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Decoder v
    -> Scan
    -> (Result Error (List v) -> msg)
    -> Cmd msg
scan pt ports decoder scanProps dt =
    scanInner ports decoder scanProps []
        |> Procedure.run pt (\( _, res ) -> dt res)


scanInner :
    Ports msg
    -> Decoder v
    -> Scan
    -> List v
    -> Procedure.Procedure e ( String, Result Error (List v) ) msg
scanInner ports decoder scanProps accum =
    Channel.open (\key -> ports.scan { id = key, req = scanEncoder scanProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.andThen
            (\{ id, res } ->
                case queryResponseDecoder decoder res of
                    Ok ( Nothing, items ) ->
                        Procedure.provide ( id, Ok items )

                    Ok ( Just lastEvaluatedKey, items ) ->
                        scanInner ports
                            decoder
                            (nextPage lastEvaluatedKey scanProps)
                            (accum ++ items)

                    Err err ->
                        Procedure.provide ( id, Err err )
            )


scanEncoder : Scan -> Value
scanEncoder scanProps =
    [ ( "TableName", Encode.string scanProps.tableName ) |> Just
    , Maybe.map (\exclusiveStartKey -> ( "ExclusiveStartKey", exclusiveStartKey )) scanProps.exclusiveStartKey
    ]
        |> Maybe.Extra.values
        |> Encode.object



---- Queries


type AttributeValue
    = StringAttr String
    | NumberAttr Int


type KeyExpression
    = KeyExpression


type KeyCondition
    = Equals String AttributeValue
    | LessThan String AttributeValue
    | LessThenOrEqual String AttributeValue
    | GreaterThan String AttributeValue
    | GreaterThanOrEqual String AttributeValue
    | Between String AttributeValue AttributeValue


type Order
    = Forward
    | Reverse


{-| A complete query against a table.
-}
type alias Query =
    { tableName : String
    , match : Match
    }


{-| A complete query against a table and index.
-}
type alias QueryIndex =
    { tableName : String
    , indexName : String
    , match : Match
    }


{-| The query conditions to be matched.
-}
type alias Match =
    { partitionKeyName : String
    , partitionKeyValue : AttributeValue
    , rangeKeyCondition : Maybe KeyCondition
    , order : Order
    , limit : Maybe Int
    , exclusiveStartKey : Maybe Value
    }


{-| From AWS DynamoDB docs, the encoding of key conditions as strings looks like:

    a = b — true if the attribute a is equal to the value b
    a < b — true if a is less than b
    a <= b — true if a is less than or equal to b
    a > b — true if a is greater than b
    a >= b — true if a is greater than or equal to b
    a BETWEEN b AND c — true if a is greater than or equal to b, and less than or equal to c.

Values must be encoded as attribute with names like ":someAttr", and these get encoded
into the "ExpressionAttributeValues" part of the query JSON. An indexing scheme is used
to ensure all the needed attributes get unique names.

-}
keyConditionAsStringAndAttrs : List KeyCondition -> ( String, List ( String, Value ) )
keyConditionAsStringAndAttrs keyConditions =
    let
        encodeKeyConditions index keyCondition =
            let
                attrName =
                    ":attr" ++ String.fromInt index
            in
            case keyCondition of
                Equals field attr ->
                    ( field ++ " = " ++ attrName, [ ( attrName, encodeAttr attr ) ] )

                LessThan field attr ->
                    ( field ++ " < " ++ attrName, [ ( attrName, encodeAttr attr ) ] )

                LessThenOrEqual field attr ->
                    ( field ++ " <= " ++ attrName, [ ( attrName, encodeAttr attr ) ] )

                GreaterThan field attr ->
                    ( field ++ " > " ++ attrName, [ ( attrName, encodeAttr attr ) ] )

                GreaterThanOrEqual field attr ->
                    ( field ++ " >= " ++ attrName, [ ( attrName, encodeAttr attr ) ] )

                Between field lowAttr highAttr ->
                    let
                        lowAttrName =
                            ":lowattr" ++ String.fromInt index

                        highAttrName =
                            ":highattr" ++ String.fromInt index
                    in
                    ( field ++ " BETWEEN " ++ lowAttrName ++ " AND " ++ highAttrName
                    , [ ( lowAttrName, encodeAttr lowAttr )
                      , ( highAttrName, encodeAttr highAttr )
                      ]
                    )
    in
    keyConditions
        |> List.indexedMap encodeKeyConditions
        |> List.unzip
        |> Tuple.mapFirst (String.join " AND ")
        |> Tuple.mapSecond List.concat


int : Int -> AttributeValue
int val =
    NumberAttr val


string : String -> AttributeValue
string val =
    StringAttr val


encodeAttr : AttributeValue -> Value
encodeAttr attr =
    case attr of
        StringAttr val ->
            Encode.string val

        NumberAttr val ->
            Encode.int val


partitionKeyEquals : String -> String -> Match
partitionKeyEquals key val =
    { partitionKeyName = key
    , partitionKeyValue = StringAttr val
    , rangeKeyCondition = Nothing
    , order = Forward
    , limit = Nothing
    , exclusiveStartKey = Nothing
    }


rangeKeyEquals : String -> AttributeValue -> Match -> Match
rangeKeyEquals keyName attr q =
    { q | rangeKeyCondition = Equals keyName attr |> Just }


rangeKeyLessThan : String -> AttributeValue -> Match -> Match
rangeKeyLessThan keyName attr q =
    { q | rangeKeyCondition = LessThan keyName attr |> Just }


rangeKeyLessThanOrEqual : String -> AttributeValue -> Match -> Match
rangeKeyLessThanOrEqual keyName attr q =
    { q | rangeKeyCondition = LessThenOrEqual keyName attr |> Just }


rangeKeyGreaterThan : String -> AttributeValue -> Match -> Match
rangeKeyGreaterThan keyName attr q =
    { q | rangeKeyCondition = GreaterThan keyName attr |> Just }


rangeKeyGreaterThanOrEqual : String -> AttributeValue -> Match -> Match
rangeKeyGreaterThanOrEqual keyName attr q =
    { q | rangeKeyCondition = GreaterThanOrEqual keyName attr |> Just }


rangeKeyBetween : String -> AttributeValue -> AttributeValue -> Match -> Match
rangeKeyBetween keyName lowAttr highAttr q =
    { q | rangeKeyCondition = Between keyName lowAttr highAttr |> Just }


orderResults : Order -> Match -> Match
orderResults ord q =
    { q | order = ord }


limitResults : Int -> Match -> Match
limitResults limit q =
    { q | limit = Just limit }


nextPage : Value -> { a | exclusiveStartKey : Maybe Value } -> { a | exclusiveStartKey : Maybe Value }
nextPage lastEvalKey q =
    { q | exclusiveStartKey = Just lastEvalKey }


query :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Decoder v
    -> Query
    -> (Result Error (List v) -> msg)
    -> Cmd msg
query pt ports decoder qry dt =
    queryInner ports decoder qry.tableName Nothing qry.match []
        |> Procedure.run pt (\( _, res ) -> dt res)


queryIndex :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Decoder v
    -> QueryIndex
    -> (Result Error (List v) -> msg)
    -> Cmd msg
queryIndex pt ports decoder qry dt =
    queryInner ports decoder qry.tableName (Just qry.indexName) qry.match []
        |> Procedure.run pt (\( _, res ) -> dt res)


queryInner :
    Ports msg
    -> Decoder v
    -> String
    -> Maybe String
    -> Match
    -> List v
    -> Procedure.Procedure e ( String, Result Error (List v) ) msg
queryInner ports decoder table maybeIndex q accum =
    Channel.open (\key -> ports.query { id = key, req = queryEncoder table maybeIndex q })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.andThen
            (\{ id, res } ->
                case queryResponseDecoder decoder res of
                    Ok ( Nothing, items ) ->
                        Procedure.provide ( id, Ok items )

                    Ok ( Just lastEvaluatedKey, items ) ->
                        queryInner ports
                            decoder
                            table
                            maybeIndex
                            (nextPage lastEvaluatedKey q)
                            (accum ++ items)

                    Err err ->
                        Procedure.provide ( id, Err err )
            )


queryEncoder : String -> Maybe String -> Match -> Value
queryEncoder table maybeIndex q =
    let
        ( keyExpressionsString, attrVals ) =
            [ Equals q.partitionKeyName q.partitionKeyValue |> Just
            , q.rangeKeyCondition
            ]
                |> Maybe.Extra.values
                |> keyConditionAsStringAndAttrs

        encodedAttrVals =
            Encode.object attrVals
    in
    [ ( "TableName", Encode.string table ) |> Just
    , Maybe.map (\index -> ( "IndexName", Encode.string index )) maybeIndex
    , ( "KeyConditionExpression", Encode.string keyExpressionsString ) |> Just
    , ( "ExpressionAttributeValues", encodedAttrVals ) |> Just
    , case q.order of
        Forward ->
            ( "ScanIndexForward", Encode.bool True ) |> Just

        Reverse ->
            ( "ScanIndexForward", Encode.bool False ) |> Just
    , Maybe.map (\limit -> ( "Limit", Encode.int limit )) q.limit
    , Maybe.map (\exclusiveStartKey -> ( "ExclusiveStartKey", exclusiveStartKey )) q.exclusiveStartKey
    ]
        |> Maybe.Extra.values
        |> Encode.object


queryResponseDecoder : Decoder v -> Value -> Result Error ( Maybe Value, List v )
queryResponseDecoder valDecoder val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Items" ->
                                Decode.map2 (\lastKey vals -> Tuple.pair lastKey vals |> Ok)
                                    (Decode.maybe (Decode.field "lastEvaluatedKey" Decode.value))
                                    (Decode.field "items" (Decode.list valDecoder))

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge
