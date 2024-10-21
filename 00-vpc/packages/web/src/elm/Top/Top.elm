module Top.Top exposing (main)

import AITrace.Component as AITrace
import Api.ChatApi.Component as ChatApi
import Api.EssifyAI.Component as EssifyAI
import Browser
import Config
import Css.Global
import Domain.Conversation exposing (Conversation, Step)
import Drawing.Component as Drawing
import Html
import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
import IntelligentAgent.Component as IntelligentAgent
import Json.Encode exposing (Value)
import Navigation exposing (Route)
import Ports
import Top.Style
import Update2 as U2
import Websockets


type alias Model =
    { -- Flags
      location : String
    , chatApiUrl : String

    -- Elm modules
    , websockets : Websockets.Model
    , intelligentAgent : IntelligentAgent.Model
    , drawing : Drawing.Model
    , trace : AITrace.Model
    , essifyAI : EssifyAI.Model

    -- Routing state
    , route : Maybe Route

    -- Shared state
    , conversation : Conversation
    , memory : Maybe Value
    }


type Msg
    = UrlChanged (Maybe Route)
    | PushUrl Route
    | WebsocketsMsg Websockets.Msg
    | IntelligentAgentMsg IntelligentAgent.Msg
    | DrawingMsg Drawing.Msg
    | AITraceMsg AITrace.Msg
    | ChatApiMsg ChatApi.Msg
    | EssifyAIMsg EssifyAI.Msg


type alias Flags =
    { location : String
    , chatApiUrl : String
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( iaMdl, iaCmds ) =
            IntelligentAgent.init IntelligentAgentMsg

        ( dMdl, dCmds ) =
            Drawing.init DrawingMsg

        ( traceMdl, traceCmds ) =
            AITrace.init AITraceMsg

        ( essifyMdl, essifyCmds ) =
            EssifyAI.init EssifyAIMsg ()

        ( socketsMdl, socketsCmds ) =
            Websockets.init WebsocketsMsg websocketsPorts
    in
    ( { location = flags.location
      , chatApiUrl = flags.chatApiUrl
      , websockets = socketsMdl
      , intelligentAgent = iaMdl.intelligentAgent
      , drawing = dMdl.drawing
      , trace = traceMdl.trace
      , essifyAI = essifyMdl
      , route = Nothing
      , conversation = { steps = [] }
      , memory = Nothing
      }
    , Cmd.batch
        [ iaCmds
        , dCmds
        , traceCmds
        , essifyCmds
        , Navigation.pushUrl "/agent"
        , socketsCmds
        ]
    )


websocketsPorts : Websockets.Ports
websocketsPorts =
    { open = Ports.wsOpen
    , onOpen = Ports.wsOnOpen
    , send = Ports.wsSend
    , onMessage = Ports.wsOnMessage
    , close = Ports.wsClose
    }


chatApiProtocol : ChatApi.Protocol Model Msg Model
chatApiProtocol =
    { toMsg = ChatApiMsg
    , onUpdate = identity
    , onConversationReady = \convId -> U2.andThen (processConversationReady convId)
    , onStepAdded = \convId step -> U2.andThen (processNewStep convId step)
    }


essifyAIProtocol : EssifyAI.Protocol Model Msg Model
essifyAIProtocol =
    { toMsg = EssifyAIMsg
    , onUpdate = identity
    , wsOpen = \id url -> U2.andThen (wsOpen id url)
    , wsSend = \id payload -> U2.andThen (wsSend id payload)
    , onConversationReady = \convId -> U2.andThen (processConversationReady convId)
    , onStepAdded = \convId step -> U2.andThen (processNewStep convId step)
    }


intelligentAgentProtocol : Model -> IntelligentAgent.Protocol Model Msg Model
intelligentAgentProtocol model =
    { toMsg = IntelligentAgentMsg
    , chatApiUrl = model.chatApiUrl
    , onUpdate = identity
    , onUserPrompt = \prompt -> U2.andThen (processUserPrompt prompt)
    }


websocketsProtocol : Model -> Websockets.Protocol Websockets.Model Msg Model
websocketsProtocol model =
    { toMsg = WebsocketsMsg
    , ports = websocketsPorts
    , onUpdate = \( wsMdl, cmds ) -> ( { model | websockets = wsMdl }, cmds )
    , onOpen = \id -> wsOpened id model
    , onMessage = \id payload -> wsMessage id payload model
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Navigation.onUrlChange (Navigation.locationHrefToRoute >> UrlChanged)
        , IntelligentAgent.subscriptions model |> Sub.map IntelligentAgentMsg
        , Drawing.subscriptions model |> Sub.map DrawingMsg
        , Websockets.subscriptions (websocketsProtocol model) model.websockets
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged route ->
            case route of
                Nothing ->
                    model |> U2.pure

                Just _ ->
                    { model | route = route }
                        |> U2.pure

        PushUrl val ->
            ( model, Navigation.routeToString val |> Navigation.pushUrl )

        WebsocketsMsg innerMsg ->
            let
                _ =
                    Debug.log "WebsocketsMsg" msg
            in
            Websockets.update (websocketsProtocol model)
                innerMsg
                model.websockets

        IntelligentAgentMsg innerMsg ->
            IntelligentAgent.update (intelligentAgentProtocol model)
                innerMsg
                model

        DrawingMsg innerMsg ->
            Drawing.update DrawingMsg
                innerMsg
                model

        AITraceMsg innerMsg ->
            AITrace.update AITraceMsg
                innerMsg
                model

        ChatApiMsg innerMsg ->
            ChatApi.update chatApiProtocol
                innerMsg
                model

        EssifyAIMsg innerMsg ->
            EssifyAI.update essifyAIProtocol
                innerMsg
                model


processUserPrompt : String -> Model -> ( Model, Cmd Msg )
processUserPrompt prompt model =
    ChatApi.userStep chatApiProtocol "convId" prompt model


processConversationReady : String -> Model -> ( Model, Cmd Msg )
processConversationReady convId model =
    IntelligentAgent.conversationReady (intelligentAgentProtocol model) convId model


processNewStep : String -> Step -> Model -> ( Model, Cmd Msg )
processNewStep convId step model =
    IntelligentAgent.addAIStep (intelligentAgentProtocol model) step model


wsOpened : String -> Model -> ( Websockets.Model, Cmd Msg ) -> ( Model, Cmd Msg )
wsOpened id model =
    \( wsMdl, cmds ) ->
        ( { model | websockets = wsMdl }, cmds )
            |> U2.andThen (EssifyAI.wsOpened essifyAIProtocol id)


wsMessage : String -> String -> Model -> ( Websockets.Model, Cmd Msg ) -> ( Model, Cmd Msg )
wsMessage id payload model =
    \( wsMdl, cmds ) ->
        ( { model | websockets = wsMdl }, cmds )
            |> U2.andThen (EssifyAI.wsMessage essifyAIProtocol id payload)


wsOpen : String -> String -> Model -> ( Model, Cmd Msg )
wsOpen id url model =
    Websockets.open (websocketsProtocol model) id url model.websockets


wsSend : String -> String -> Model -> ( Model, Cmd Msg )
wsSend id payload model =
    Websockets.send (websocketsProtocol model) id payload model.websockets


view : Model -> Html.Html Msg
view model =
    fullBody model |> HS.toUnstyled


fullBody : Model -> Html Msg
fullBody model =
    case model.route of
        Just Navigation.Agent ->
            HS.div
                [ HA.id "top-container"
                ]
                [ Top.Style.rawCssStyle
                , Top.Style.style Config.config |> Css.Global.global
                , IntelligentAgent.style |> Css.Global.global
                , Drawing.style |> Css.Global.global
                , IntelligentAgent.view
                    { toMsg = IntelligentAgentMsg
                    , pushUrl = PushUrl
                    }
                    model
                , leftMenu
                , Drawing.view DrawingMsg model
                , rightOverlay
                ]

        Just Navigation.AgentTrace ->
            HS.div
                [ HA.id "top-container"
                ]
                [ Top.Style.style Config.config |> Css.Global.global
                , AITrace.style |> Css.Global.global
                , leftMenu
                , AITrace.view AITraceMsg model
                ]

        Nothing ->
            HS.div [] []


leftMenu : Html msg
leftMenu =
    HS.div [ HA.id "left-menu" ]
        []


rightOverlay : Html msg
rightOverlay =
    HS.div [ HA.id "right-overlay" ]
        []
