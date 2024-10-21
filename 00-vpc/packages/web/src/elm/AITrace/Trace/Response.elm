module AITrace.Trace.Response exposing (Model, response)

import AITrace.Trace.Spec as Spec exposing (LogEntry(..), ViewContextIF)
import Html.Styled as HS exposing (Html)
import Json.Encode as Encode exposing (Value)


type alias Model =
    { output : String
    }


response : LogEntry msg
response =
    Spec.logEntry
        { view = view
        , encode = encode
        }
        { output = "Give some consideration to the following tips on Sprint Planning: blah, blah, blah..."
        }


encode : Model -> Value
encode model =
    [ ( "output", Encode.string model.output )
    ]
        |> Encode.object


view : ViewContextIF msg -> Model -> Html msg
view _ model =
    HS.div []
        [ HS.h2 [] [ HS.text "Response" ]
        , HS.p [] [ HS.text model.output ]
        ]
