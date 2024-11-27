module AWS.Dynamo exposing
    ( Ports
    , dynamoApi, DynamoApi
    , Put
    , Get
    , Delete
    , Query, Order(..), partitionKeyEquals, limitResults, orderResults
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

@docs Query, Order, partitionKeyEquals, limitResults, orderResults
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
    { get : Get -> (Result Error (Maybe Value) -> msg) -> Cmd msg
    , put : Put -> (Result Error () -> msg) -> Cmd msg
    , delete : Delete -> (Result Error () -> msg) -> Cmd msg
    , batchGet : BatchGet -> (Result Error (List Value) -> msg) -> Cmd msg
    , batchPut : BatchPut -> (Result Error () -> msg) -> Cmd msg
    , query : String -> Maybe String -> Query -> (Result Error (List Value) -> msg) -> Cmd msg
    , queryIndex : String -> String -> Query -> (Result Error (List Value) -> msg) -> Cmd msg
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



-- Database operations


type Error
    = Error { message : String, details : Value }
    | DecodeError String


errorToString : Error -> String
errorToString err =
    case err of
        Error { message } ->
            message

        DecodeError val ->
            val


errorToDetails : Error -> { message : String, details : Value }
errorToDetails err =
    case err of
        Error { message, details } ->
            { message = message
            , details = details
            }

        DecodeError message ->
            { message = message
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


type alias Put =
    { tableName : String
    , item : Value
    }


put :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Put
    -> (Result Error () -> msg)
    -> Cmd msg
put pt ports putProps dt =
    Channel.open (\key -> ports.put { id = key, req = putEncoder putProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> putResponseDecoder res |> dt)


putEncoder : Put -> Value
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
        |> Result.mapError (Decode.errorToString >> DecodeError >> Err)
        |> Result.Extra.merge



---- Get a document from DynamoDB


type alias Get =
    { tableName : String
    , key : Value
    }


get :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Get
    -> (Result Error (Maybe Value) -> msg)
    -> Cmd msg
get pt ports getProps dt =
    Channel.open (\key -> ports.get { id = key, req = getEncoder getProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> getResponseDecoder res |> dt)


getEncoder : Get -> Value
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
        |> Result.mapError (Decode.errorToString >> DecodeError >> Err)
        |> Result.Extra.merge



---- Delete


type alias Delete =
    { tableName : String
    , key : Value
    }


delete :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Delete
    -> (Result Error () -> msg)
    -> Cmd msg
delete pt ports deleteProps dt =
    Channel.open (\key -> ports.delete { id = key, req = deleteEncoder deleteProps })
        |> Channel.connect ports.response
        |> Channel.filter (\key { id } -> id == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\{ res } -> deleteResponseDecoder res |> dt)


deleteEncoder : Delete -> Value
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
        |> Result.mapError (Decode.errorToString >> DecodeError >> Err)
        |> Result.Extra.merge



---- Batch Put


type alias BatchPut =
    { tableName : String
    , items : List Value
    }


batchPut :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> BatchPut
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


batchPutEncoder : BatchPut -> Value
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
        |> Result.mapError (Decode.errorToString >> DecodeError >> Err)
        |> Result.Extra.merge



---- Batch Get


type alias BatchGet =
    { tableName : String
    , keys : List Value
    }


batchGet :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> BatchGet
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
        |> Result.mapError (Decode.errorToString >> DecodeError >> Err)
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


type alias Query =
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


partitionKeyEquals : String -> String -> Query
partitionKeyEquals key val =
    { partitionKeyName = key
    , partitionKeyValue = StringAttr val
    , rangeKeyCondition = Nothing
    , order = Forward
    , limit = Nothing
    , exclusiveStartKey = Nothing
    }


rangeKeyEquals : String -> AttributeValue -> Query -> Query
rangeKeyEquals keyName attr q =
    { q | rangeKeyCondition = Equals keyName attr |> Just }


rangeKeyLessThan : String -> AttributeValue -> Query -> Query
rangeKeyLessThan keyName attr q =
    { q | rangeKeyCondition = LessThan keyName attr |> Just }


rangeKeyLessThanOrEqual : String -> AttributeValue -> Query -> Query
rangeKeyLessThanOrEqual keyName attr q =
    { q | rangeKeyCondition = LessThenOrEqual keyName attr |> Just }


rangeKeyGreaterThan : String -> AttributeValue -> Query -> Query
rangeKeyGreaterThan keyName attr q =
    { q | rangeKeyCondition = GreaterThan keyName attr |> Just }


rangeKeyGreaterThanOrEqual : String -> AttributeValue -> Query -> Query
rangeKeyGreaterThanOrEqual keyName attr q =
    { q | rangeKeyCondition = GreaterThanOrEqual keyName attr |> Just }


rangeKeyBetween : String -> AttributeValue -> AttributeValue -> Query -> Query
rangeKeyBetween keyName lowAttr highAttr q =
    { q | rangeKeyCondition = Between keyName lowAttr highAttr |> Just }


orderResults : Order -> Query -> Query
orderResults ord q =
    { q | order = ord }


limitResults : Int -> Query -> Query
limitResults limit q =
    { q | limit = Just limit }


nextPage : Value -> Query -> Query
nextPage lastEvalKey q =
    { q | exclusiveStartKey = Just lastEvalKey }


query :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> String
    -> Maybe String
    -> Query
    -> (Result Error (List Value) -> msg)
    -> Cmd msg
query pt ports table maybeIndex q dt =
    queryInner ports table maybeIndex q []
        |> Procedure.run pt (\( _, res ) -> dt res)


queryIndex :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> String
    -> String
    -> Query
    -> (Result Error (List Value) -> msg)
    -> Cmd msg
queryIndex pt ports table index q dt =
    queryInner ports table (Just index) q []
        |> Procedure.run pt (\( _, res ) -> dt res)


queryInner :
    Ports msg
    -> String
    -> Maybe String
    -> Query
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


queryEncoder : String -> Maybe String -> Query -> Value
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
        |> Result.mapError (Decode.errorToString >> DecodeError >> Err)
        |> Result.Extra.merge
