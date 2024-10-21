module IntelligentAgent.Chat.Spec exposing (Chat(..), ChatCons, ChatIF, ChatStep(..), ChatStepCons, ChatStepIF, ViewContextIF, logEntry, trace)

import AdHoc as AH
import ChatBox.Editor as Editor
import Html.Styled exposing (Html)
import IntelligentAgent.Msg exposing (Msg)
import Json.Encode exposing (Value)


type Chat
    = Chat ChatIF


type alias ChatIF =
    { view : () -> Html Msg
    , add : ChatStep Msg -> Chat
    }


type alias ChatCons rep =
    { view : rep -> Html Msg
    , add : ChatStep Msg -> rep -> rep
    }


trace : ChatCons rep -> rep -> Chat
trace cons =
    AH.impl ChatIF
        |> AH.add (\rep () -> cons.view rep)
        |> AH.wrap (\raise rep e -> cons.add e rep |> raise)
        |> AH.map Chat
        |> AH.init (\raise rep -> raise rep)


type alias ViewContextIF msg =
    { noop : msg
    , toEditorMsg : Editor.Msg -> msg
    }


type ChatStep msg
    = ChatStep (ChatStepIF msg)


type alias ChatStepIF msg =
    { encode : Value
    , view : ViewContextIF msg -> Html msg
    }


type alias ChatStepCons msg rep =
    { encode : rep -> Value
    , view : ViewContextIF msg -> rep -> Html msg
    }


logEntry : ChatStepCons msg rep -> rep -> ChatStep msg
logEntry cons =
    AH.impl ChatStepIF
        |> AH.add (\rep -> cons.encode rep)
        |> AH.add (\rep vc -> cons.view vc rep)
        |> AH.map ChatStep
        |> AH.init (\raise rep -> raise rep)
