module Snapshot.Snapshot exposing (Flags, Model, MomentoSecret, Msg, main)

import Http.Request as Request exposing (Method(..))
import Http.Response as Response
import HttpServer exposing (ApiRequest, HttpSessionKey)
import Ports
import Update2 as U2
import Url exposing (Url)


type alias Model =
    { -- Flags
      momentoApiKey : String
    , channelApiUrl : String
    , channelTable : String
    , eventLogTable : String

    -- Shared state
    }


type Msg
    = HttpRequest HttpSessionKey (Result HttpServer.Error (ApiRequest Route))


type alias MomentoSecret =
    { apiKey : String
    , refreshToken : String
    , restEndpoint : String
    }


type alias Flags =
    { momentoSecret : MomentoSecret
    , channelApiUrl : String
    , channelTable : String
    , eventLogTable : String
    }


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


type Route
    = Snapshot


routeParser : Url -> Maybe Route
routeParser _ =
    --UP.oneOf
    --    [ UP.map ChannelRoot (UP.s "channel")
    --    ]
    --    |> UP.parse
    Just Snapshot


httpServerApi : HttpServer.HttpServerApi Msg Route
httpServerApi =
    { ports =
        { request = Ports.requestPort
        , response = Ports.responsePort
        }
    , parseRoute = routeParser
    }
        |> HttpServer.httpServerApi


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { momentoApiKey = flags.momentoSecret.apiKey
      , channelApiUrl = flags.channelApiUrl
      , channelTable = flags.channelTable
      , eventLogTable = flags.eventLogTable
      }
    , Cmd.batch
        []
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    [ httpServerApi.request HttpRequest
    ]
        |> Sub.batch


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HttpRequest session result ->
            case result of
                Ok apiRequest ->
                    processRoute session apiRequest model

                Err httpError ->
                    ( model
                    , httpError
                        |> HttpServer.errorToString
                        |> Response.err500
                        |> httpServerApi.response session
                    )



-- API Routing


processRoute : HttpSessionKey -> ApiRequest Route -> Model -> ( Model, Cmd Msg )
processRoute session apiRequest model =
    case ( Request.method apiRequest.request, apiRequest.route ) of
        ( POST, Snapshot ) ->
            U2.pure model
                |> U2.andMap (takeSnapshot session model)

        _ ->
            U2.pure model


takeSnapshot _ _ model =
    U2.pure model
