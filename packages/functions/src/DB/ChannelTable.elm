module DB.ChannelTable exposing
    ( Key
    , Record
    )

import Json.Encode as Encode exposing (Value)
import Time exposing (Posix)


type alias Key =
    { id : String
    }


type alias Record =
    { id : String
    , updatedAt : Posix
    , modelTopic : String
    , saveTopic : String
    , saveList : String
    , webhook : String
    }
