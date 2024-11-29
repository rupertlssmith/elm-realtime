module Top.Top exposing (..)

import App.Component as App
import Browser
import Config
import Css.Global
import Html
import Html.Styled as HS exposing (Html)
import Html.Styled.Attributes as HA
import Json.Decode as Decode
import Momento exposing (Error, OpenParams, SubscribeParams)
import Navigation exposing (Route)
import Ports
import Top.Style
import Update2 as U2


type alias Model =
    { -- Flags
      location : String
    , momentoApiKey : String

    -- Elm modules
    , app : App.Lifecycle

    -- Routing state
    , route : Maybe Route

    -- Shared state
    }


type Msg
    = UrlChanged (Maybe Route)
    | PushUrl Route
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
            App.init "aflpeYGXfU" appProtocol.toMsg
    in
    ( { location = flags.location
      , momentoApiKey =
            Decode.decodeString (Decode.field "apiKey" Decode.string) flags.momentoApiKey
                |> Result.withDefault ""
      , app = appMdl
      , route = Nothing
      }
    , Cmd.batch
        [ Navigation.pushUrl "/app"
        , appCmds
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
    , createWebhook = Ports.mmCreateWebhook
    , onError = Ports.mmOnError
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

        AppMsg innerMsg ->
            App.update appProtocol
                innerMsg
                model


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
