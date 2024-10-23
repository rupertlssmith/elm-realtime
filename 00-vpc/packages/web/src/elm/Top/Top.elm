module Top.Top exposing (main)

import Browser
import Config
import Css.Global
import Html
import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
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

    -- Routing state
    , route : Maybe Route

    -- Shared state
    }


type Msg
    = UrlChanged (Maybe Route)
    | PushUrl Route
    | WebsocketsMsg Websockets.Msg


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
        ( socketsMdl, socketsCmds ) =
            Websockets.init WebsocketsMsg websocketsPorts
    in
    ( { location = flags.location
      , chatApiUrl = flags.chatApiUrl
      , websockets = socketsMdl
      , route = Nothing
      }
    , Cmd.batch
        [ Navigation.pushUrl "/agent"
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


wsOpened : String -> Model -> ( Websockets.Model, Cmd Msg ) -> ( Model, Cmd Msg )
wsOpened id model =
    \( wsMdl, cmds ) ->
        --  |> U2.andThen (EssifyAI.wsOpened essifyAIProtocol id)
        ( { model | websockets = wsMdl }, cmds )


wsMessage : String -> String -> Model -> ( Websockets.Model, Cmd Msg ) -> ( Model, Cmd Msg )
wsMessage id payload model =
    \( wsMdl, cmds ) ->
        --|> U2.andThen (EssifyAI.wsMessage essifyAIProtocol id payload)
        ( { model | websockets = wsMdl }, cmds )


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
                , leftMenu
                , rightOverlay
                ]

        Just Navigation.AgentTrace ->
            HS.div
                [ HA.id "top-container"
                ]
                [ Top.Style.style Config.config |> Css.Global.global
                , leftMenu
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
