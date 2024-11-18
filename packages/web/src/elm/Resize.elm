module Resize exposing (resizeDecoder)

import Geometry exposing (VScene)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Vector2d


resizeDecoder : Decoder VScene
resizeDecoder =
    Decode.succeed Vector2d.unitless
        |> DE.andMap (Decode.at [ "detail", "w" ] Decode.float)
        |> DE.andMap (Decode.at [ "detail", "h" ] Decode.float)
