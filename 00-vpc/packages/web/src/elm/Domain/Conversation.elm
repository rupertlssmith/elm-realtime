module Domain.Conversation exposing (Conversation, Step(..), Trace)

{-| Domain model of the Conversation.

A Conversation is a stream of events called Steps. Each Step is an input from an intelligent
actor participating in the conversation, either a User or an Artificial Intelligence.

The AI steps will additionally contain Trace elements, which is a debug trace of how the AI
arrived at its decisions in regard to its participation in the Conversation. What data did it
consult in its knowledge base? what queries structured or natural language it run? what decision
points did it formulate? and so on.

-}

import Json.Encode exposing (Value)


type alias Conversation =
    { steps : List Step
    }


type Step
    = AIStep
        { content : String
        , traces : List Trace
        , memory : Value
        }
    | UserStep
        { content : String
        , memory : Maybe Value
        }


type alias Trace =
    { typeName : String
    , trace : Value
    }
