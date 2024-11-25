module AWS.Dynamo exposing
    ( Put, put
    , Get, get
    , Delete, delete
    )

{-| A wrapper around the AWS DynamoDB Document API.

@docs Put, put
@docs Get, get
@docs Delete, delete

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
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Put
    -> (Result Error () -> msg)
    -> Cmd msg
put pt ports putProps dt =
    Channel.open (\key -> ports.put ( key, putEncoder putProps ))
        |> Channel.connect ports.response
        |> Channel.filter (\key ( respKey, _ ) -> respKey == key)
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
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> Get
    -> (Result Error (Maybe Value) -> msg)
    -> Cmd msg
get pt ports getProps dt =
    Channel.open (\key -> ports.get ( key, getEncoder getProps ))
        |> Channel.connect ports.response
        |> Channel.filter (\key ( respKey, _ ) -> respKey == key)
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
    Channel.open (\key -> ports.delete ( key, deleteEncoder deleteProps ))
        |> Channel.connect ports.response
        |> Channel.filter (\key ( respKey, _ ) -> respKey == key)
        |> Channel.acceptOne
        |> Procedure.run pt (\( _, res ) -> deleteResponseDecoder res |> dt)


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
                                Decode.field "errorMsg" Decode.string
                                    |> Decode.map (Error >> Err)
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
    batchPutInner pt ports batchPutProps.tableName batchPutProps.items
        |> Procedure.run pt (\( _, res ) -> dt res)


batchPutInner :
    (Procedure.Program.Msg msg -> msg)
    -> Ports msg
    -> String
    -> List Value
    -> Procedure.Procedure e ( String, Result Error () ) msg
batchPutInner pt ports table vals =
    let
        firstBatch =
            List.take 25 vals

        remainder =
            List.drop 25 vals
    in
    Channel.open (\key -> ports.batchWrite ( key, batchPutEncoder { tableName = table, items = firstBatch } ))
        |> Channel.connect ports.response
        |> Channel.filter (\key ( respKey, _ ) -> respKey == key)
        |> Channel.acceptOne
        |> Procedure.andThen
            (\( key, val ) ->
                case batchPutResponseDecoder val of
                    Ok res ->
                        case remainder of
                            [] ->
                                Procedure.provide ( key, Ok res )

                            moreItems ->
                                batchPutInner pt ports table moreItems

                    Err err ->
                        Procedure.provide ( key, Err err )
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
                                Decode.field "errorMsg" Decode.string
                                    |> Decode.map (Error >> Err)
                    )
    in
    Decode.decodeValue decoder val
        |> Result.mapError (Decode.errorToString >> DecodeError >> Err)
        |> Result.Extra.merge



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
