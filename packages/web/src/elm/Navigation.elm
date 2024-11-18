port module Navigation exposing (Route(..), click, locationHrefToRoute, onUrlChange, pushUrl, routeToString)

import Html.Styled as HS exposing (Attribute, Html)
import Html.Styled.Events as HE
import Json.Decode as Decode
import Url
import Url.Parser


port onUrlChange : (String -> msg) -> Sub msg


port pushUrl : String -> Cmd msg


type Route
    = App


link : msg -> List (Attribute msg) -> List (Html msg) -> Html msg
link href attrs children =
    HS.a (HE.preventDefaultOn "click" (Decode.succeed ( href, True )) :: attrs) children


click : msg -> Attribute msg
click href =
    HE.preventDefaultOn "click" (Decode.succeed ( href, True ))


locationHrefToRoute : String -> Maybe Route
locationHrefToRoute locationHref =
    case Url.fromString locationHref of
        Nothing ->
            Nothing

        Just url ->
            Url.Parser.parse myParser url


myParser : Url.Parser.Parser (Route -> a) a
myParser =
    Url.Parser.oneOf
        [ Url.Parser.map App (Url.Parser.s "app")
        ]


routeToString : Route -> String
routeToString route =
    case route of
        App ->
            "app"
