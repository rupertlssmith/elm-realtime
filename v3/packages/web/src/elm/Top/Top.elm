module Top.Top exposing (..)

import App.Component as App
import Browser
import Config
import Css.Global
import Html
import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
import Json.Decode as Decode
import Momento exposing (Error, OpenParams)
import Navigation exposing (Route)
import Ports
import Top.Style
import Update2 as U2


type alias Model =
    { -- Flags
      location : String

    --, chatApiUrl : String
    , momentoApiKey : String

    -- Elm modules
    , app : App.Model
    , websockets : Momento.Model

    -- Routing state
    , route : Maybe Route

    -- Shared state
    }


type Msg
    = UrlChanged (Maybe Route)
    | PushUrl Route
    | MomentoMsg Momento.Msg
    | AppMsg App.Msg


type alias Flags =
    { location : String
    , momentoApiKey : String
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
        ( appMdl, appCmds ) =
            App.init appProtocol.toMsg

        ( socketsMdl, socketsCmds ) =
            Momento.init MomentoMsg momentoPorts
    in
    ( { location = flags.location
      , momentoApiKey =
            Decode.decodeString (Decode.field "apiKey" Decode.string) flags.momentoApiKey
                |> Result.withDefault ""
      , app = appMdl
      , websockets = socketsMdl
      , route = Nothing
      }
    , Cmd.batch
        [ Navigation.pushUrl "/app"
        , appCmds
        , socketsCmds
        ]
    )


momentoPorts : Momento.Ports
momentoPorts =
    { open = Ports.mmOpen
    , send = Ports.mmSend
    , close = Ports.mmClose
    , onOpen = Ports.mmOnOpen
    , onMessage = Ports.mmOnMessage
    , onError = Ports.mmOnError
    }


momentoProtocol : Model -> Momento.Protocol Momento.Model Msg Model
momentoProtocol model =
    { toMsg = MomentoMsg
    , ports = momentoPorts
    , onUpdate = \( wsMdl, cmds ) -> ( { model | websockets = wsMdl }, cmds )
    , onOpen = \id -> wsOpened id model
    , onMessage = \id payload -> wsMessage id payload model
    , onError = \id error -> wsError id error model
    }


appProtocol : App.Protocol Model Msg Model
appProtocol =
    { toMsg = AppMsg
    , onUpdate = identity
    , wsOpen = \id url -> U2.andThen (wsOpen id url)
    , wsSend = \id payload -> U2.andThen (wsSend id payload)
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Navigation.onUrlChange (Navigation.locationHrefToRoute >> UrlChanged)
        , Momento.subscriptions (momentoProtocol model) model.websockets
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

        MomentoMsg innerMsg ->
            Momento.update (momentoProtocol model)
                innerMsg
                model.websockets

        AppMsg innerMsg ->
            App.update appProtocol
                innerMsg
                model


wsOpened : String -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
wsOpened id model =
    \( wsMdl, cmds ) ->
        ( { model | websockets = wsMdl }, cmds )
            |> U2.andThen (App.wsOpened appProtocol id)


wsMessage : String -> String -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
wsMessage id payload model =
    \( wsMdl, cmds ) ->
        ( { model | websockets = wsMdl }, cmds )
            |> U2.andThen (App.wsMessage appProtocol id payload)


wsError : String -> Error -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
wsError id payload model =
    \( wsMdl, cmds ) ->
        ( { model | websockets = wsMdl }, cmds )
            |> U2.andThen (App.wsError appProtocol id payload)


wsOpen : String -> OpenParams -> Model -> ( Model, Cmd Msg )
wsOpen id params model =
    Momento.open (momentoProtocol model) id params model.websockets


wsSend : String -> String -> Model -> ( Model, Cmd Msg )
wsSend id payload model =
    Momento.send (momentoProtocol model) id payload model.websockets


view : Model -> Html.Html Msg
view model =
    fullBody model |> HS.toUnstyled


fullBody : Model -> Html Msg
fullBody model =
    case model.route of
        Just Navigation.App ->
            HS.div
                [ HA.id "top-container"
                ]
                [ Top.Style.rawCssStyle
                , Top.Style.style Config.config |> Css.Global.global
                , leftMenu
                , App.view model
                ]

        Nothing ->
            HS.div [] []


leftMenu : Html msg
leftMenu =
    HS.div [ HA.id "left-menu" ]
        []
