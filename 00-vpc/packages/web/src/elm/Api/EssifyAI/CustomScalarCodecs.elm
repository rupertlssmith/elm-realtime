module Api.EssifyAI.CustomScalarCodecs exposing (DateTime, Id, Json, codecs)

import Api.EssifyAI.Scalar as Scalar
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Time


type alias Id =
    String


type alias DateTime =
    Time.Posix


type alias Json =
    Value


codecs : Scalar.Codecs DateTime Id Json
codecs =
    Scalar.defineCodecs
        { codecDateTime =
            { encoder = Time.posixToMillis >> Encode.int
            , decoder = Decode.int |> Decode.map Time.millisToPosix
            }
        , codecId =
            { encoder = Encode.string
            , decoder = Decode.string
            }
        , codecJson =
            { encoder = identity
            , decoder = Decode.value
            }
        }
