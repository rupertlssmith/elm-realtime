module Api.ChatApi.Remote exposing (PostPrompt, postPrompt)

import Domain.Conversation exposing (Step(..), Trace)
import Http
import Json
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Json.Encode as Encode exposing (Value)


encodeStep : Step -> Value
encodeStep step =
    case step of
        AIStep { traces } ->
            Encode.object
                [ ( "__typename", Encode.string "AIStep" )
                , ( "traces", Encode.list encodeTrace traces )
                ]

        UserStep { content, memory } ->
            [ ( "prompt", Encode.string content ) |> Just
            , Maybe.map (\mem -> ( "memory", mem )) memory
            ]
                |> List.filterMap identity
                |> Encode.object


encodeTrace : Trace -> Value
encodeTrace trace =
    let
        tn =
            Encode.object
                [ ( "__typename", Encode.string trace.typeName )
                ]
    in
    Json.combineFields trace.trace tn


stepDecoder : Decoder Step
stepDecoder =
    aiStepDecoder


aiStepDecoder : Decoder Step
aiStepDecoder =
    Decode.succeed
        (\traces memory content ->
            { traces = traces
            , content = content
            , memory = memory
            }
        )
        |> DE.andMap (Decode.field "traces" (Decode.list traceDecoder))
        |> DE.andMap (Decode.field "memory" Decode.value)
        |> DE.andMap (Decode.at [ "response", "text" ] Decode.string)
        |> Decode.map AIStep


traceDecoder : Decoder Trace
traceDecoder =
    Decode.succeed Trace
        |> DE.andMap (Decode.at [ "payload", "subtype" ] Decode.string)
        |> DE.andMap (Decode.at [ "payload", "data" ] Decode.value)
        |> Decode.map (Debug.log "trace")


type alias PostPrompt =
    { prompt : String
    , memory : Maybe Value
    }


postPrompt : String -> (Http.Error -> msg) -> (Step -> msg) -> PostPrompt -> Cmd msg
postPrompt url errFn okFn prompt =
    let
        body =
            [ ( "prompt", Encode.string prompt.prompt ) |> Just
            , Maybe.map (\mem -> ( "memory", mem )) prompt.memory
            ]
                |> List.filterMap identity
                |> Encode.object

        decoder =
            stepDecoder
    in
    Http.post
        { url = url
        , body = Http.jsonBody body
        , expect =
            Http.expectJson
                (\resp ->
                    case resp of
                        Ok val ->
                            okFn val

                        Err err ->
                            errFn err
                )
                decoder
        }
