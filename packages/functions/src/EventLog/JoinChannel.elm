module EventLog.JoinChannel exposing (..)

import AWS.Dynamo as Dynamo exposing (Order(..))
import DB.EventLogTable as EventLogTable
import ErrorFormat exposing (ErrorFormat)
import EventLog.Apis as Apis
import EventLog.Model exposing (Model(..), ReadyState)
import EventLog.Msg exposing (Msg(..))
import EventLog.Route exposing (Route)
import Http.Response as Response exposing (Response)
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Json.Encode as Encode exposing (Value)
import Procedure
import Update2 as U2


type alias JoinChannel a =
    { a
        | momentoApiKey : String
        , eventLogTable : String
        , eventLog : Model
    }


setModel : JoinChannel a -> Model -> JoinChannel a
setModel m x =
    { m | eventLog = x }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


{-| Join a Channel:

    * Look up the latest snapshot of the named channel, if any.
    * Look up the saved events for the named channel, if any.
    * Return the snapshot, and any saved events coming after it.

-}
joinChannel :
    HttpSessionKey
    -> ReadyState
    -> ApiRequest Route
    -> String
    -> JoinChannel a
    -> ( JoinChannel a, Cmd Msg )
joinChannel session state apiRequest channelName component =
    let
        procedure : Procedure.Procedure Response Response Msg
        procedure =
            Procedure.provide channelName
                -- |>  Procedure.andThen (fetchLatestSnapshot ...)
                |> Procedure.andThen (fetchSavedEventsSince component 1)
                |> Procedure.mapError (Debug.log "error" >> ErrorFormat.encodeErrorFormat >> Response.err500json)
                |> Procedure.map (\events -> Response.ok200json (Encode.list encodeEvent events))
    in
    ( state
    , Procedure.try ProcedureMsg (HttpResponse session) procedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)



-- fetchLatestSnapshot


fetchSavedEventsSince :
    JoinChannel a
    -> Int
    -> String
    -> Procedure.Procedure ErrorFormat (List EventLogTable.Record) Msg
fetchSavedEventsSince component startSeq channelName =
    let
        match =
            Dynamo.partitionKeyEquals "id" channelName
                |> Dynamo.rangeKeyGreaterThanOrEqual "seq" (Dynamo.int startSeq)
                |> Dynamo.orderResults Forward

        query =
            { tableName = component.eventLogTable
            , match = match
            }
    in
    Apis.eventLogTableApi.query query
        |> Procedure.fetchResult
        |> Procedure.mapError Dynamo.errorToDetails


encodeEvent : EventLogTable.Record -> Value
encodeEvent record =
    [ ( "rt", Encode.string "P" )
    , ( "seq", Encode.int record.seq )
    , ( "payload", record.event )
    ]
        |> Encode.object
