module IntelligentAgent.ChatStep exposing (Block(..), HRefProps, Inline(..), Item, ItemOrigin(..), stringTitleToItem)

import GapBuffer exposing (GapBuffer)
import GapBufferUtils as GBU


type alias Item =
    { title : String
    , body : GapBuffer Block Block
    , origin : ItemOrigin
    }


type ItemOrigin
    = OriginAssistant
    | OriginUser


type Block
    = Body (GapBuffer Inline Inline)
    | Child String


type Inline
    = HRef HRefProps
    | Element String
    | Text (GapBuffer String String)


type alias HRefProps =
    { url : String
    , text : String
    }


stringTitleToItem : ItemOrigin -> String -> String -> Item
stringTitleToItem origin title val =
    { title = title
    , body =
        String.words val
            |> GBU.listToGapBuffer
            |> GBU.gapBufferToEnd
            |> Text
            |> List.singleton
            |> GBU.listToGapBuffer
            |> GBU.gapBufferToEnd
            |> Body
            |> List.singleton
            |> GBU.listToGapBuffer
            |> GBU.gapBufferToEnd
    , origin = origin
    }
