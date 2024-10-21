module Api.ChatApi.Component exposing
    ( Component
    , Msg(..)
    , Protocol
    , startConversation
    , update
    , userStep
    )

import Api.ChatApi.Remote as Remote
import Domain.Conversation exposing (Conversation, Step(..))
import Http
import Json.Encode exposing (Value)
import List.Extra
import Update2 as U2


type alias Component a =
    { a
        | chatApiUrl : String
        , conversation : Conversation
        , memory : Maybe Value
    }


type Msg
    = AIResponse Step
    | ApiError Http.Error


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )

    -- Conversation interface.
    , onConversationReady : String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onStepAdded : String -> Step -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }


startConversation : Protocol (Component a) msg model -> Component a -> ( model, Cmd msg )
startConversation protocol model =
    U2.pure model
        |> protocol.onConversationReady "convId"


userStep : Protocol (Component a) msg model -> String -> String -> Component a -> ( model, Cmd msg )
userStep protocol convId prompt model =
    ( model
    , Remote.postPrompt model.chatApiUrl
        ApiError
        AIResponse
        { prompt = prompt, memory = model.memory }
    )
        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
        |> protocol.onUpdate


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg model =
    case msg of
        AIResponse step ->
            U2.pure model
                |> U2.andThen (addStepToConversation step)
                |> protocol.onStepAdded "convId" step

        ApiError err ->
            let
                _ =
                    Debug.log "AipError" err
            in
            U2.pure model
                |> protocol.onUpdate


addStepToConversation : Step -> Component a -> ( Component a, Cmd msg )
addStepToConversation step model =
    case step of
        AIStep { memory } ->
            { model
                | conversation = { steps = step :: model.conversation.steps }
                , memory = Just memory
            }
                |> U2.pure

        _ ->
            { model | conversation = { steps = step :: model.conversation.steps } }
                |> U2.pure
