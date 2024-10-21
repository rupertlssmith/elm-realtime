module AITrace.Trace.Spec exposing (LogEntry(..), LogEntryCons, LogEntryIF, Msg(..), Trace(..), TraceCons, TraceIF, ViewContextIF, logEntry, trace)

import AdHoc as AH
import Html.Styled exposing (Html)
import Json.Encode exposing (Value)


type Msg
    = Noop


type Trace
    = Trace TraceIF


type alias TraceIF =
    { view : () -> Html Msg
    , add : LogEntry Msg -> Trace
    }


type alias TraceCons rep =
    { view : rep -> Html Msg
    , add : LogEntry Msg -> rep -> rep
    }


trace : TraceCons rep -> rep -> Trace
trace cons =
    AH.impl TraceIF
        |> AH.add (\rep () -> cons.view rep)
        |> AH.wrap (\raise rep e -> cons.add e rep |> raise)
        |> AH.map Trace
        |> AH.init (\raise rep -> raise rep)


type alias ViewContextIF msg =
    { noop : msg
    }


type LogEntry msg
    = LogEntry (LogEntryIF msg)


type alias LogEntryIF msg =
    { encode : Value
    , view : ViewContextIF msg -> Html msg
    }


type alias LogEntryCons msg rep =
    { encode : rep -> Value
    , view : ViewContextIF msg -> rep -> Html msg
    }


logEntry : LogEntryCons msg rep -> rep -> LogEntry msg
logEntry cons =
    AH.impl LogEntryIF
        |> AH.add (\rep -> cons.encode rep)
        |> AH.add (\rep vc -> cons.view vc rep)
        |> AH.map LogEntry
        |> AH.init (\raise rep -> raise rep)
