module AWS.Dynamo exposing
    ( Ports
    , dynamoApi, DynamoApi
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


# Packaged API

@docs dynamoApi, DynamoApi


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

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Json.Encode as Encode exposing (Value)
import Maybe.Extra
import Procedure
import Procedure.Channel as Channel
import Procedure.Program
import Result.Extra


type alias Ports msg =
    { get : { id : String, req : Value } -> Cmd msg
    , put : { id : String, req : Value } -> Cmd msg
    , delete : { id : String, req : Value } -> Cmd msg
    , batchGet : { id : String, req : Value } -> Cmd msg
    , batchWrite : { id : String, req : Value } -> Cmd msg
    , query : { id : String, req : Value } -> Cmd msg
    , response : ({ id : String, res : Value } -> msg) -> Sub msg
    }


type alias DynamoApi msg =
    { get : Get Value -> (Result Error (Maybe Value) -> msg) -> Cmd msg
    , put : Put Value -> (Result Error () -> msg) -> Cmd msg
    , delete : Delete Value -> (Result Error () -> msg) -> Cmd msg
    , batchGet : BatchGet Value -> (Result Error (List Value) -> msg) -> Cmd msg
    , batchPut : BatchPut Value -> (Result Error () -> msg) -> Cmd msg
    , query : Query -> (Result Error (List Value) -> msg) -> Cmd msg
    , queryIndex : QueryIndex -> (Result Error (List Value) -> msg) -> Cmd msg
    }


type alias DynamoTypedApi k v msg =
    { get : Get k -> (Result Error (Maybe v) -> msg) -> Cmd msg

    --, put : Put v -> (Result Error () -> msg) -> Cmd msg
    --, delete : Delete k -> (Result Error () -> msg) -> Cmd msg
    --, batchGet : BatchGet k -> (Result Error (List v) -> msg) -> Cmd msg
    --, batchPut : BatchPut v -> (Result Error () -> msg) -> Cmd msg
    --, query : Query -> (Result Error (List v) -> msg) -> Cmd msg
    --, queryIndex : QueryIndex -> (Result Error (List v) -> msg) -> Cmd msg
    }


dynamoApi : (Procedure.Program.Msg msg -> msg) -> Ports msg -> DynamoApi msg
dynamoApi pt ports =
    { get = get pt ports
    , put = put pt ports
    , delete = delete pt ports
    , batchGet = batchGet pt ports
    , batchPut = batchPut pt ports
    , query = query pt ports
    , queryIndex = queryIndex pt ports
    }


dynamoTypedApi : (Procedure.Program.Msg msg -> msg) -> Ports msg -> (k -> Value) -> (v -> Value) -> Decoder v -> DynamoTypedApi k v msg
dynamoTypedApi pt ports keyEncoder valEncoder decoder =
    { get = typedGet pt ports keyEncoder decoder

    --, put = typedPut pt ports valEncoder
    --, delete = typedDelete pt ports keyEncoder
    --, batchGet = typedBatchGet pt ports keyEncoder decoder
    --, batchPut = typedBatchPut pt ports valEncoder
    --, query = typedQuery pt ports decoder
    --, queryIndex = typedQueryIndex pt ports decoder
    }


decodeTypedResults : Decoder v -> Result Error (Maybe Value) -> Result Error (Maybe v)
decodeTypedResults decoder jsonResult =
    jsonResult
        |> Result.map
            (Maybe.map
                (Decode.decodeValue decoder
                    >> Result.map Just
                    >> Result.mapError DecodeError
                )
                >> Maybe.withDefault (Ok Nothing)
            )
        |> Result.Extra.join


typedGet pt ports encoder decoder getProps dt =
    get
        pt
        ports
        { tableName = getProps.tableName
        , key = encoder getProps.key
        }
        (decodeTypedResults decoder >> dt)


typedPut pt ports encoder =
    put pt ports


typedDelete pt ports encoder =
    delete pt ports


typedBatchGet pt ports encoder decoder =
    batchGet pt ports


typedBatchPut pt ports encoder =
    batchPut pt ports


typedQuery pt ports decoder =
    query pt ports


typedQueryIndex pt ports decoder =
    queryIndex pt ports



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
    -> Put Value
    -> (Result Error () -> msg)
    -> Cmd msg
put pt ports putProps dt =
    Channel.open (\key -> ports.put { id = key, req = putEncoder putProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> putResponseDecoder res |> dt)


putEncoder : Put Value -> Value
putEncoder putOp =
    Encode.object
        [ ( "TableName", Encode.string putOp.tableName )
        , ( "Item", putOp.item )
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



---- Get a document from DynamoDB


type alias Get k =
    { tableName : String
    , key : k
    }


get :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Get Value
    -> (Result Error (Maybe Value) -> msg)
    -> Cmd msg
get pt ports getProps dt =
    Channel.open (\key -> ports.get { id = key, req = getEncoder getProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> getResponseDecoder res |> dt)


getEncoder : Get Value -> Value
getEncoder getOp =
    Encode.object
        [ ( "TableName", Encode.string getOp.tableName )
        , ( "Key", getOp.key )
        ]


getResponseDecoder : Value -> Result Error (Maybe Value)
getResponseDecoder val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Item" ->
                                Decode.at [ "item", "Item" ] Decode.value
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
    -> Delete Value
    -> (Result Error () -> msg)
    -> Cmd msg
delete pt ports deleteProps dt =
    Channel.open (\key -> ports.delete { id = key, req = deleteEncoder deleteProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> deleteResponseDecoder res |> dt)


deleteEncoder : Delete Value -> Value
deleteEncoder deleteOp =
    Encode.object
        [ ( "TableName", Encode.string deleteOp.tableName )
        , ( "Key", deleteOp.key )
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
    -> BatchPut Value
    -> (Result Error () -> msg)
    -> Cmd msg
batchPut pt ports batchPutProps dt =
    batchPutInner ports batchPutProps.tableName batchPutProps.items
        |> Procedure.run pt (\( _, res ) -> dt res)


batchPutInner :
    Ports msg
    -> String
    -> List Value
    -> Procedure.Procedure e ( String, Result Error () ) msg
batchPutInner ports table vals =
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
                , req = batchPutEncoder { tableName = table, items = firstBatch }
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
                                batchPutInner ports table moreItems

                    Err err ->
                        Procedure.provide ( id, Err err )
            )


batchPutEncoder : BatchPut Value -> Value
batchPutEncoder putOp =
    let
        encodeItem item =
            Encode.object
                [ ( "PutRequest"
                  , Encode.object
                        [ ( "Item", item ) ]
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


type alias BatchGet v =
    { tableName : String
    , keys : List v
    }


batchGet :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> BatchGet Value
    -> (Result Error (List Value) -> msg)
    -> Cmd msg
batchGet pt ports batchGetProps dt =
    Channel.open
        (\key ->
            ports.batchWrite
                { id = key
                , req =
                    batchGetEncoder
                        { tableName = batchGetProps.tableName
                        , keys = batchGetProps.keys
                        }
                }
        )
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> batchGetResponseDecoder batchGetProps.tableName res |> dt)


batchGetEncoder getOp =
    Encode.object
        [ ( "RequestItems"
          , Encode.object
                [ ( getOp.tableName
                  , Encode.object
                        [ ( "Keys", Encode.list identity getOp.keys ) ]
                  )
                ]
          )
        ]


batchGetResponseDecoder : String -> Value -> Result Error (List Value)
batchGetResponseDecoder tableName val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Item" ->
                                Decode.at [ "item", "Responses", tableName ] (Decode.list Decode.value)
                                    |> Decode.map Ok

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge



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


nextPage : Value -> Match -> Match
nextPage lastEvalKey q =
    { q | exclusiveStartKey = Just lastEvalKey }


query :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Query
    -> (Result Error (List Value) -> msg)
    -> Cmd msg
query pt ports qry dt =
    queryInner ports qry.tableName Nothing qry.match []
        |> Procedure.run pt (\( _, res ) -> dt res)


queryIndex :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> QueryIndex
    -> (Result Error (List Value) -> msg)
    -> Cmd msg
queryIndex pt ports qry dt =
    queryInner ports qry.tableName (Just qry.indexName) qry.match []
        |> Procedure.run pt (\( _, res ) -> dt res)


queryInner :
    Ports msg
    -> String
    -> Maybe String
    -> Match
    -> List Value
    -> Procedure.Procedure e ( String, Result Error (List Value) ) msg
queryInner ports table maybeIndex q accum =
    Channel.open (\key -> ports.query { id = key, req = queryEncoder table maybeIndex q })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.andThen
            (\{ id, res } ->
                case queryResponseDecoder res of
                    Ok ( Nothing, items ) ->
                        Procedure.provide ( id, Ok items )

                    Ok ( Just lastEvaluatedKey, items ) ->
                        queryInner ports
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


queryResponseDecoder : Value -> Result Error ( Maybe Value, List Value )
queryResponseDecoder val =
    let
        decoder =
            Decode.field "type_" Decode.string
                |> Decode.andThen
                    (\type_ ->
                        case type_ of
                            "Items" ->
                                Decode.map2 (\lastKey vals -> Tuple.pair lastKey vals |> Ok)
                                    (Decode.maybe (Decode.field "lastEvaluatedKey" Decode.value))
                                    (Decode.field "items" (Decode.list Decode.value))

                            _ ->
                                errorDecoder
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (DecodeError >> Err)
        |> Result.Extra.merge
