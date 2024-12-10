module EventLog.Protocol exposing (Protocol)

import EventLog.Msg exposing (Msg)


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }
