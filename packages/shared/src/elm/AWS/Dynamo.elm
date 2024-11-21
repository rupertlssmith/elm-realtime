module AWS.Dynamo exposing
    ( Put, put
    , Get, get
    )

{-| A wrapper around the AWS DynamoDB Document API.

@docs Put, put
@docs Get, get

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Procedure
import Procedure.Channel as Channel
import Procedure.Program
import Result.Extra


type alias Ports msg =
    { get : ( String, Value ) -> Cmd msg
    , put : ( String, Value ) -> Cmd msg
    , delete : ( String, Value ) -> Cmd msg
    , batchGet : ( String, Value ) -> Cmd msg
    , batchWrite : ( String, Value ) -> Cmd msg
    , query : ( String, Value ) -> Cmd msg
    , response : (( String, Value ) -> msg) -> Sub msg
    }



-- Database operations


type Error
    = Error String
    | DecodeError String


type alias Delete =
    { tableName : String
    , key : Value
    }


type alias UpdateKey =
    { tableName : String
    , oldKey : Value
    , item : Value
    }


type alias BatchGet =
    { tableName : String
    , keys : List Value
    }



-- Looping operations
--
--type Msg
--    = BatchPutLoop PutResponse String (PutResponse -> msg) (List Value)
--    | QueryLoop (List Value) String Query (QueryResponse Value -> msg) (QueryResponse Value)
--
--
--update : Protocol Model Msg model -> Msg -> Model -> ( model, Cmd msg )
--update msg model =
--    case msg of
--        BatchPutLoop response table tagger responseFn remainder ->
--            batchPutLoop response table tagger responseFn remainder model
--
--        QueryLoop accum table q tagger responseFn results ->
--            queryLoop accum table q tagger responseFn results model
--
--
--batchPutLoop response table tagger responseFn remainder model =
--    case response of
--        PutOk ->
--            case remainder of
--                [] ->
--                    ( model, responseFn PutOk |> Task.Extra.message )
--
--                _ ->
--                    batchPutInner table
--                        tagger
--                        responseFn
--                        remainder
--
--        PutError dbErrorMsg ->
--            ( model, PutError dbErrorMsg |> responseFn |> Task.Extra.message )
--
--
--queryLoop accum table q tagger responseFn results model =
--    case results of
--        QueryItems Nothing items ->
--            ( model, QueryItems Nothing (accum ++ items) |> responseFn |> Task.Extra.message )
--
--        QueryItems (Just lastEvaluatedKey) items ->
--            queryInner (accum ++ items)
--                table
--                (nextPage lastEvaluatedKey q)
--                tagger
--                responseFn
--
--        QueryError dbErrorMsg ->
--            ( model, QueryError dbErrorMsg |> responseFn |> Task.Extra.message )
--
--
--
---- Put a document in DynamoDB


type alias Put =
    { tableName : String
    , item : Value
    }


put :
    Ports msg
    -> Put
    -> (Procedure.Program.Msg msg -> msg)
    -> (Result Error () -> msg)
    -> Cmd msg
put ports putProps pt dt =
    Channel.open (\key -> ports.put ( key, putEncoder putProps ))
        |> Channel.connect ports.response
        |> Channel.acceptOne
        |> Procedure.run pt (\( _, res ) -> putResponseDecoder res |> dt)


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
                                Decode.field "errorMsg" Decode.string
                                    |> Decode.map (Error >> Err)
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
    Ports msg
    -> Get
    -> (Procedure.Program.Msg msg -> msg)
    -> (Result Error (Maybe Value) -> msg)
    -> Cmd msg
get ports getProps pt dt =
    Channel.open (\key -> ports.get ( key, getEncoder getProps ))
        |> Channel.connect ports.response
        |> Channel.acceptOne
        |> Procedure.run pt (\( _, res ) -> getResponseDecoder res |> dt)


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
                                Decode.field "errorMsg" Decode.string
                                    |> Decode.map (Error >> Err)
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (Decode.errorToString >> DecodeError >> Err)
        |> Result.Extra.merge



---- Delete
--
--
--delete :
--    String
--    -> (k -> Value)
--    -> k
--    -> (DeleteResponse -> msg)
--delete table encoder key responseFn conn =
--    dynamoDeletePort
--        (deleteEncoder encoder { tableName = table, key = key })
--        (deleteResponseDecoder >> responseFn)
--
--
--deleteEncoder : (k -> Value) -> Delete k -> Value
--deleteEncoder encoder deleteOp =
--    Encode.object
--        [ ( "TableName", Encode.string deleteOp.tableName )
--        , ( "Key", encoder deleteOp.key )
--        ]
--
--
--deleteResponseDecoder : Value -> DeleteResponse
--deleteResponseDecoder val =
--    let
--        decoder =
--            Decode.field "type_" Decode.string
--                |> Decode.andThen
--                    (\type_ ->
--                        case type_ of
--                            "Ok" ->
--                                Decode.succeed DeleteOk
--
--                            _ ->
--                                Decode.field "errorMsg" Decode.string
--                                    |> Decode.map DeleteError
--                    )
--    in
--    Decode.decodeValue decoder val
--        |> Result.mapError (Decode.errorToString >> DeleteError)
--        |> Result.Extra.merge
--
--
--
---- Update Key
--
--
--updateKey :
--    String
--    -> (k -> Value)
--    -> (a -> Value)
--    -> k
--    -> a
--    -> (PutResponse -> msg)
--updateKey table keyEncoder itemEncoder oldKey newItem responseFn conn =
--    dynamoBatchWritePort
--        (updateKeyEncoder
--            { tableName = table
--            , oldKey = keyEncoder oldKey
--            , item = itemEncoder newItem
--            }
--        )
--        (putResponseDecoder >> responseFn)
--
--
--updateKeyEncoder : UpdateKey Value Value -> Value
--updateKeyEncoder updateKeyOp =
--    let
--        encodeItem item =
--            Encode.object
--                [ ( "PutRequest"
--                  , Encode.object [ ( "Item", item ) ]
--                  )
--                ]
--
--        encodeKey key =
--            Encode.object
--                [ ( "DeleteRequest"
--                  , Encode.object [ ( "Key", key ) ]
--                  )
--                ]
--    in
--    Encode.object
--        [ ( "RequestItems"
--          , Encode.object
--                [ ( updateKeyOp.tableName
--                  , Encode.list identity
--                        [ encodeItem updateKeyOp.item
--                        , encodeKey updateKeyOp.oldKey
--                        ]
--                  )
--                ]
--          )
--        ]
--
--
--
---- Batch Put


type alias BatchPut =
    { tableName : String
    , items : List Value
    }



--
--batchPut :
--    String
--    -> (a -> Value)
--    -> List a
--    -> (Msg msg -> msg)
--    -> (PutResponse -> msg)
--batchPut table encoder vals tagger responseFn =
--    batchPutInner table tagger responseFn (List.map encoder vals)
--
--
--batchPutInner :
--    String
--    -> (Msg msg -> msg)
--    -> (PutResponse -> msg)
--    -> List Value
--batchPutInner table tagger responseFn vals =
--    let
--        firstBatch =
--            List.take 25 vals
--
--        remainder =
--            List.drop 25 vals
--    in
--    dynamoBatchWritePort
--        (batchPutEncoder { tableName = table, items = firstBatch })
--        (\val ->
--            BatchPutLoop (putResponseDecoder val) table tagger responseFn remainder |> tagger
--        )
--
--
--batchPutEncoder : BatchPut Value -> Value
--batchPutEncoder putOp =
--    let
--        encodeItem item =
--            Encode.object
--                [ ( "PutRequest"
--                  , Encode.object
--                        [ ( "Item", item ) ]
--                  )
--                ]
--    in
--    Encode.object
--        [ ( "RequestItems"
--          , Encode.object
--                [ ( putOp.tableName
--                  , Encode.list encodeItem putOp.items
--                  )
--                ]
--          )
--        ]
--
--
--
---- Batch Get
--
--
--batchGet :
--    String
--    -> (k -> Value)
--    -> List k
--    -> Decoder a
--    -> (BatchGetResponse a -> msg)
--batchGet table encoder keys decoder responseFn =
--    dynamoBatchGetPort
--        (batchGetEncoder encoder { tableName = table, keys = keys })
--        (batchGetResponseDecoder table decoder >> responseFn)
--
--
--batchGetEncoder : (k -> Value) -> BatchGet k -> Value
--batchGetEncoder encoder getOp =
--    Encode.object
--        [ ( "RequestItems"
--          , Encode.object
--                [ ( getOp.tableName
--                  , Encode.object
--                        [ ( "Keys"
--                          , Encode.list encoder getOp.keys
--                          )
--                        ]
--                  )
--                ]
--          )
--        ]
--
--
--batchGetResponseDecoder : String -> Decoder a -> Value -> BatchGetResponse a
--batchGetResponseDecoder tableName itemDecoder val =
--    let
--        decoder =
--            Decode.field "type_" Decode.string
--                |> Decode.andThen
--                    (\type_ ->
--                        case type_ of
--                            "Item" ->
--                                Decode.at [ "item", "Responses", tableName ] (Decode.list itemDecoder)
--                                    |> Decode.map BatchGetItems
--
--                            _ ->
--                                Decode.field "errorMsg" Decode.string
--                                    |> Decode.map BatchGetError
--                    )
--    in
--    Decode.decodeValue decoder val
--        |> Result.mapError (Decode.errorToString >> BatchGetError)
--        |> Result.Extra.merge
--
--
--
---- Queries
--
--


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



--
--
--{-| From AWS DynamoDB docs, the encoding of key conditions as strings looks like:
--
--    a = b — true if the attribute a is equal to the value b
--    a < b — true if a is less than b
--    a <= b — true if a is less than or equal to b
--    a > b — true if a is greater than b
--    a >= b — true if a is greater than or equal to b
--    a BETWEEN b AND c — true if a is greater than or equal to b, and less than or equal to c.
--
--Values must be encoded as attribute with names like ":someAttr", and these get encoded
--into the "ExpressionAttributeValues" part of the query JSON. An indexing scheme is used
--to ensure all the needed attributes get unique names.
--
---}
--keyConditionAsStringAndAttrs : List KeyCondition -> ( String, List ( String, Value ) )
--keyConditionAsStringAndAttrs keyConditions =
--    let
--        encodeKeyConditions index keyCondition =
--            let
--                attrName =
--                    ":attr" ++ String.fromInt index
--            in
--            case keyCondition of
--                Equals field attr ->
--                    ( field ++ " = " ++ attrName, [ ( attrName, encodeAttr attr ) ] )
--
--                LessThan field attr ->
--                    ( field ++ " < " ++ attrName, [ ( attrName, encodeAttr attr ) ] )
--
--                LessThenOrEqual field attr ->
--                    ( field ++ " <= " ++ attrName, [ ( attrName, encodeAttr attr ) ] )
--
--                GreaterThan field attr ->
--                    ( field ++ " > " ++ attrName, [ ( attrName, encodeAttr attr ) ] )
--
--                GreaterThanOrEqual field attr ->
--                    ( field ++ " >= " ++ attrName, [ ( attrName, encodeAttr attr ) ] )
--
--                Between field lowAttr highAttr ->
--                    let
--                        lowAttrName =
--                            ":lowattr" ++ String.fromInt index
--
--                        highAttrName =
--                            ":highattr" ++ String.fromInt index
--                    in
--                    ( field ++ " BETWEEN " ++ lowAttrName ++ " AND " ++ highAttrName
--                    , [ ( lowAttrName, encodeAttr lowAttr )
--                      , ( highAttrName, encodeAttr highAttr )
--                      ]
--                    )
--    in
--    keyConditions
--        |> List.indexedMap encodeKeyConditions
--        |> List.unzip
--        |> Tuple.mapFirst (String.join " AND ")
--        |> Tuple.mapSecond List.concat
--
--
--int : Int -> AttributeValue
--int val =
--    NumberAttr val
--
--
--string : String -> AttributeValue
--string val =
--    StringAttr val
--
--
--encodeAttr : AttributeValue -> Value
--encodeAttr attr =
--    case attr of
--        StringAttr val ->
--            Encode.string val
--
--        NumberAttr val ->
--            Encode.int val
--
--
--partitionKeyEquals : String -> String -> Query
--partitionKeyEquals key val =
--    { partitionKeyName = key
--    , partitionKeyValue = StringAttr val
--    , rangeKeyCondition = Nothing
--    , order = Forward
--    , limit = Nothing
--    , exclusiveStartKey = Nothing
--    }
--
--
--rangeKeyEquals : String -> AttributeValue -> Query -> Query
--rangeKeyEquals keyName attr q =
--    { q | rangeKeyCondition = Equals keyName attr |> Just }
--
--
--rangeKeyLessThan : String -> AttributeValue -> Query -> Query
--rangeKeyLessThan keyName attr q =
--    { q | rangeKeyCondition = LessThan keyName attr |> Just }
--
--
--rangeKeyLessThanOrEqual : String -> AttributeValue -> Query -> Query
--rangeKeyLessThanOrEqual keyName attr q =
--    { q | rangeKeyCondition = LessThenOrEqual keyName attr |> Just }
--
--
--rangeKeyGreaterThan : String -> AttributeValue -> Query -> Query
--rangeKeyGreaterThan keyName attr q =
--    { q | rangeKeyCondition = GreaterThan keyName attr |> Just }
--
--
--rangeKeyGreaterThanOrEqual : String -> AttributeValue -> Query -> Query
--rangeKeyGreaterThanOrEqual keyName attr q =
--    { q | rangeKeyCondition = GreaterThanOrEqual keyName attr |> Just }
--
--
--rangeKeyBetween : String -> AttributeValue -> AttributeValue -> Query -> Query
--rangeKeyBetween keyName lowAttr highAttr q =
--    { q | rangeKeyCondition = Between keyName lowAttr highAttr |> Just }
--
--
--orderResults : Order -> Query -> Query
--orderResults ord q =
--    { q | order = ord }
--
--
--limitResults : Int -> Query -> Query
--limitResults limit q =
--    { q | limit = Just limit }
--
--
--nextPage : Value -> Query -> Query
--nextPage lastEvalKey q =
--    { q | exclusiveStartKey = Just lastEvalKey }
--
--
--query :
--    String
--    -> Query
--    -> (Msg msg -> msg)
--    -> (QueryResponse Value -> msg)
--query table q tagger responseFn =
--    queryInner [] table q tagger responseFn
--
--
--queryInner :
--    List Value
--    -> String
--    -> Query
--    -> (Msg msg -> msg)
--    -> (QueryResponse Value -> msg)
--queryInner accum table q tagger responseFn =
--    dynamoQueryPort
--        (queryEncoder table Nothing q)
--        (\val -> QueryLoop accum table q tagger responseFn (queryResponseDecoder Decode.value val) |> tagger)
--
--
--queryIndex :
--    String
--    -> String
--    -> Query
--    -> Decoder a
--    -> (QueryResponse a -> msg)
--queryIndex table index q decoder responseFn =
--    dynamoQueryPort
--        (queryEncoder table (Just index) q)
--        (queryResponseDecoder decoder >> responseFn)
--
--
--queryEncoder : String -> Maybe String -> Query -> Value
--queryEncoder table maybeIndex q =
--    let
--        ( keyExpressionsString, attrVals ) =
--            [ Equals q.partitionKeyName q.partitionKeyValue |> Just
--            , q.rangeKeyCondition
--            ]
--                |> Maybe.Extra.values
--                |> keyConditionAsStringAndAttrs
--
--        encodedAttrVals =
--            Encode.object attrVals
--    in
--    [ ( "TableName", Encode.string table ) |> Just
--    , Maybe.map (\index -> ( "IndexName", Encode.string index )) maybeIndex
--    , ( "KeyConditionExpression", Encode.string keyExpressionsString ) |> Just
--    , ( "ExpressionAttributeValues", encodedAttrVals ) |> Just
--    , case q.order of
--        Forward ->
--            ( "ScanIndexForward", Encode.bool True ) |> Just
--
--        Reverse ->
--            ( "ScanIndexForward", Encode.bool False ) |> Just
--    , Maybe.map (\limit -> ( "Limit", Encode.int limit )) q.limit
--    , Maybe.map (\exclusiveStartKey -> ( "ExclusiveStartKey", exclusiveStartKey )) q.exclusiveStartKey
--    ]
--        |> Maybe.Extra.values
--        |> Encode.object
--
--
--queryResponseDecoder : Decoder a -> Value -> QueryResponse a
--queryResponseDecoder itemDecoder val =
--    let
--        decoder =
--            Decode.field "type_" Decode.string
--                |> Decode.andThen
--                    (\type_ ->
--                        case type_ of
--                            "Items" ->
--                                Decode.map2 QueryItems
--                                    (Decode.maybe (Decode.field "lastEvaluatedKey" Decode.value))
--                                    (Decode.field "items" (Decode.list itemDecoder))
--
--                            _ ->
--                                Decode.field "errorMsg" Decode.string
--                                    |> Decode.map QueryError
--                    )
--    in
--    Decode.decodeValue decoder val
--        |> Result.mapError (Decode.errorToString >> QueryError)
--        |> Result.Extra.merge
