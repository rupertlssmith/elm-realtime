module Names exposing
    ( cacheName
    , metadataKeyName
    , modelTopicName
    , nameGenerator
    , notifyTopicName
    , saveListName
    , webhookName
    )

import Random
import Random.Char
import Random.String


nameGenerator : Random.Generator String
nameGenerator =
    Random.String.string 10 Random.Char.english


modelTopicName : String -> String
modelTopicName channel =
    channel ++ "-modeltopic"


notifyTopicName : String -> String
notifyTopicName channel =
    channel ++ "-savetopic"


cacheName : String -> String
cacheName channel =
    "elm-realtime" ++ "-cache"


saveListName : String -> String
saveListName channel =
    channel ++ "-savelist"


webhookName : String -> String
webhookName channel =
    channel ++ "-webhook"


metadataKeyName : String -> String
metadataKeyName channel =
    channel ++ "-metadata"
