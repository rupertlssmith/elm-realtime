module Top.Top exposing (..)

import App.Component as App
import Browser
import Config
import Css.Global
import Html
import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
import Json.Decode as Decode
import Momento exposing (Error, Op, OpenParams, SubscribeParams)
import Navigation exposing (Route)
import Ports
import Top.Style
import Update2 as U2


type alias Model =
    { -- Flags
      location : String
    , momentoApiKey : String

    -- Elm modules
    , app : App.Model
    , momento : Momento.Model

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
            App.init "abczxy" appProtocol.toMsg

        ( socketsMdl, socketsCmds ) =
            Momento.init MomentoMsg momentoPorts
    in
    ( { location = flags.location
      , momentoApiKey =
            Decode.decodeString (Decode.field "apiKey" Decode.string) flags.momentoApiKey
                |> Result.withDefault ""
      , app = appMdl
      , momento = socketsMdl
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
    , onOpen = Ports.mmOnOpen
    , close = Ports.mmClose
    , subscribe = Ports.mmSubscribe
    , onSunscribe = Ports.mmOnSubscribe
    , publish = Ports.mmSend
    , onMessage = Ports.mmOnMessage
    , pushList = Ports.mmPushList
    , onError = Ports.mmOnError
    }


momentoProtocol : Model -> Momento.Protocol Momento.Model Msg Model
momentoProtocol model =
    { toMsg = MomentoMsg
    , ports = momentoPorts
    , onUpdate = \( wsMdl, cmds ) -> ( { model | momento = wsMdl }, cmds )
    , onOpen = \id -> mmOpened id model
    , onSubscribe = \id params -> mmSubscribed id params model
    , onMessage = \id payload -> mmMessage id payload model
    , onError = \id error -> mmError id error model
    }


appProtocol : App.Protocol Model Msg Model
appProtocol =
    { toMsg = AppMsg
    , onUpdate = identity
    , mmOpen = \id params -> U2.andThen (mmOpen id params)
    , mmSubscribe = \id params -> U2.andThen (mmSubscribe id params)
    , mmOps = \id ops -> U2.andThen (mmOps id ops)
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Navigation.onUrlChange (Navigation.locationHrefToRoute >> UrlChanged)
        , Momento.subscriptions (momentoProtocol model) model.momento
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
                model.momento

        AppMsg innerMsg ->
            App.update appProtocol
                innerMsg
                model


mmOpened : String -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmOpened id model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )
            |> U2.andThen (App.mmOpened appProtocol id)


mmSubscribed : String -> SubscribeParams -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmSubscribed id params model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )
            |> U2.andThen (App.mmSubscribed appProtocol id params)


mmMessage : String -> String -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmMessage id payload model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )
            |> U2.andThen (App.mmMessage appProtocol id payload)


mmError : String -> Error -> Model -> ( Momento.Model, Cmd Msg ) -> ( Model, Cmd Msg )
mmError id payload model =
    \( wsMdl, cmds ) ->
        ( { model | momento = wsMdl }, cmds )
            |> U2.andThen (App.mmError appProtocol id payload)


mmOpen : String -> OpenParams -> Model -> ( Model, Cmd Msg )
mmOpen id params model =
    Momento.open (momentoProtocol model) id params model.momento


mmSubscribe : String -> SubscribeParams -> Model -> ( Model, Cmd Msg )
mmSubscribe id params model =
    Momento.subscribe (momentoProtocol model) id params model.momento


mmOps : String -> List Op -> Model -> ( Model, Cmd Msg )
mmOps id ops model =
    Momento.processOps (momentoProtocol model) id ops model.momento


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
