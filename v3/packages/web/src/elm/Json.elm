module Json exposing (combineFields)

{-| Helper functions for working with JSON.

@doc combineFields

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


{-| Combines the fields of two JSON objects encoded as `Value`
into a single object. If there are fields in the second object
with the same name as fields in the first one, those will replace
the corresponding fields in the first object.

If one or both arguments are not objects, this will silently fail
by returning the value of `Encode.null`.

-}
combineFields : Value -> Value -> Value
combineFields a b =
    let
        aEntries =
            Decode.decodeValue (Decode.keyValuePairs Decode.value) a

        bEntries =
            Decode.decodeValue (Decode.keyValuePairs Decode.value) b
    in
    Result.map2 (++) aEntries bEntries
        |> Result.map Encode.object
        |> Result.withDefault Encode.null
