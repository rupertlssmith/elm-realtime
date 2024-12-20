module EventLog.JoinChannel exposing (..)

import AWS.Dynamo as Dynamo exposing (Order(..))
import DB.EventLogTable as EventLogTable
import Dict exposing (Dict)
import ErrorFormat exposing (ErrorFormat)
import EventLog.Apis as Apis
import EventLog.LatestSnapshot as LatestSnapshot
import EventLog.Model exposing (Model(..), ReadyState)
import EventLog.Msg exposing (Msg(..))
import EventLog.Route exposing (Route)
import Http.Response as Response exposing (Response)
import HttpServer exposing (ApiRequest, Error, HttpSessionKey)
import Json.Encode as Encode exposing (Value)
import Procedure
import Realtime exposing (Snapshot)
import Update2 as U2


type alias JoinChannel a =
    { a
        | momentoApiKey : String
        , eventLogTable : String
        , snapshotTable : String
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
procedure :
    HttpSessionKey
    -> ReadyState
    -> ApiRequest Route
    -> String
    -> JoinChannel a
    -> ( JoinChannel a, Cmd Msg )
procedure session state apiRequest channelName component =
    let
        _ =
            Debug.log "JoinChannel.procedure" "called"

        encodeEvent : EventLogTable.Record -> Value
        encodeEvent record =
            Realtime.encodePersistedEvent record.seq record.event

        response snapshot events =
            Maybe.map (.model >> Realtime.encodeSnapshotEvent) snapshot
                :: List.map (\event -> encodeEvent event |> Just) events
                |> List.filterMap identity
                |> Encode.list identity

        innerProcedure : Procedure.Procedure Response Response Msg
        innerProcedure =
            Procedure.provide { cache = state.cache }
                |> Procedure.andThen (LatestSnapshot.getLatestSnapshotFromTable component channelName)
                |> Procedure.andThen (fetchSavedEventsSince component channelName)
                |> Procedure.mapError (Debug.log "error" >> ErrorFormat.encodeErrorFormat >> Response.err500json)
                |> Procedure.map (\{ maybeLatest, laterEvents } -> Response.ok200json (response maybeLatest laterEvents))
    in
    ( state
    , Procedure.try ProcedureMsg (HttpResponse session) innerProcedure
    )
        |> U2.andMap (ModelReady |> switchState)
        |> Tuple.mapFirst (setModel component)


fetchSavedEventsSince :
    JoinChannel a
    -> String
    ->
        { cache : Dict String (Snapshot Value)
        , maybeLatest : Maybe (Snapshot Value)
        }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , maybeLatest : Maybe (Snapshot Value)
            , laterEvents : List EventLogTable.Record
            }
            Msg
fetchSavedEventsSince component channelName state =
    let
        _ =
            Debug.log "JoinChannel.fetchSavedEventsSince" "called"

        _ =
            Debug.log "state" state

        startSeq =
            case state.maybeLatest of
                Just latest ->
                    latest.seq

                Nothing ->
                    1

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
        |> Procedure.map
            (\events ->
                { cache = state.cache
                , maybeLatest = state.maybeLatest
                , laterEvents = events
                }
            )
