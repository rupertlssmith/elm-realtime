module EventLog.GetAvailableChannel exposing (getAvailableChannel)

import AWS.Dynamo as Dynamo exposing (Error(..))
import Codec
import DB.ChannelTable as ChannelTable
import ErrorFormat exposing (ErrorFormat)
import EventLog.Apis as Apis
import EventLog.Model exposing (Model(..), ReadyState)
import EventLog.Msg exposing (Msg(..))
import Http.Response as Response exposing (Response)
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Json.Encode as Encode
import Procedure
import Update2 as U2


type alias GetAvailableChannel a =
    { a
        | channelTable : String
        , eventLog : Model
    }


setModel : GetAvailableChannel a -> Model -> GetAvailableChannel a
setModel m x =
    { m | eventLog = x }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


{-| Look for an available channel.
-}
getAvailableChannel :
    HttpSessionKey
    -> ReadyState
    -> GetAvailableChannel a
    -> ( GetAvailableChannel a, Cmd Msg )
getAvailableChannel session state component =
    let
        procedure : Procedure.Procedure Response Response Msg
        procedure =
            Procedure.provide ()
                |> Procedure.andThen (findAvailableChannel component)
                |> Procedure.mapError (ErrorFormat.encodeErrorFormat >> Response.err500json)
                |> Procedure.map
                    (\maybeChannel ->
                        case maybeChannel of
                            Just channel ->
                                Response.ok200json (channel |> Codec.encoder ChannelTable.recordCodec)

                            Nothing ->
                                Response.notFound400json Encode.null
                    )
    in
    ( state
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)


findAvailableChannel :
    GetAvailableChannel a
    -> ()
    -> Procedure.Procedure ErrorFormat (Maybe ChannelTable.Record) Msg
findAvailableChannel component _ =
    Apis.channelTableApi.scan
        { tableName = component.channelTable
        , exclusiveStartKey = Nothing
        }
        |> Procedure.fetchResult
        |> Procedure.map List.head
        |> Procedure.mapError Dynamo.errorToDetails
