module ErrorFormat exposing
    ( ErrorFormat
    , encodeErrorFormat
    )

import Json.Encode as Encode exposing (Value)


type alias ErrorFormat =
    { message : String
    , details : Value
    }


encodeErrorFormat : ErrorFormat -> Value
encodeErrorFormat error =
    [ ( "message", Encode.string error.message )
    , ( "details", error.details )
    ]
        |> Encode.object
