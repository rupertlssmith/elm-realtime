module EventLog.LatestSnapshot exposing
    ( getLatestSnapshotFromCache
    , getLatestSnapshotFromTable
    )

import AWS.Dynamo as Dynamo exposing (Error(..), Order(..))
import Dict exposing (Dict)
import ErrorFormat exposing (ErrorFormat)
import EventLog.Apis as Apis
import EventLog.Msg exposing (Msg(..))
import Json.Decode exposing (Decoder, Value)
import Procedure
import Realtime exposing (RTMessage(..), Snapshot, SnapshotEvent)


type alias LatestSnapshot a =
    { a
        | snapshotTable : String
    }


getLatestSnapshotFromCache :
    LatestSnapshot a
    -> String
    -> { cache : Dict String (Snapshot Value) }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , maybeLatest : Maybe (Snapshot Value)
            }
            Msg
getLatestSnapshotFromCache component channelName state =
    let
        _ =
            Debug.log "LatestSnapshot.getLatestSnapshotFromCache" "called"
    in
    Procedure.provide
        { cache = state.cache
        , maybeLatest = Dict.get channelName state.cache
        }


getLatestSnapshotFromTable :
    LatestSnapshot a
    -> String
    -> { cache : Dict String (Snapshot Value) }
    ->
        Procedure.Procedure ErrorFormat
            { cache : Dict String (Snapshot Value)
            , maybeLatest : Maybe (Snapshot Value)
            }
            Msg
getLatestSnapshotFromTable component channelName state =
    let
        _ =
            Debug.log "LatestSnapshot.getLatestSnapshotFromTable" "called"
    in
    (Apis.snapshotTableApi component.snapshotTable).findLatestSnapshot channelName
        |> Procedure.fetchResult
        |> Procedure.mapError Dynamo.errorToDetails
        |> Procedure.map
            (\queryResult ->
                case queryResult of
                    [] ->
                        { cache = state.cache, maybeLatest = Nothing }

                    r :: _ ->
                        { cache = state.cache, maybeLatest = Just { seq = r.seq, model = r.snapshot } }
            )
