module AITrace.Trace.Prompt exposing (Model, prompt)

import AITrace.Trace.Spec as Spec exposing (LogEntry(..), ViewContextIF)
import Html.Styled as HS exposing (Html)
import Json.Encode as Encode exposing (Value)


type alias Model =
    { input : String
    }


prompt : LogEntry msg
prompt =
    Spec.logEntry
        { view = view
        , encode = encode
        }
        { input = "How can we make our sprint planning more effective?"
        }


encode : Model -> Value
encode model =
    [ ( "input", Encode.string model.input )
    ]
        |> Encode.object


view : ViewContextIF msg -> Model -> Html msg
view _ model =
    HS.div []
        [ HS.h2 [] [ HS.text "Prompt" ]
        , HS.p [] [ HS.text model.input ]
        ]
