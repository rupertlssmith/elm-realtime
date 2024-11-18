module Config exposing (config)


type alias Config =
    { defaultZoom : Float
    , maxZoom : Float
    , minZoom : Float
    , containerElementId : String
    , leftMenuWidth : Float
    , rightOverlayWidth : Float
    }


config : Config
config =
    { defaultZoom = 1.0
    , maxZoom = 5
    , minZoom = 0.2
    , containerElementId = "drawing-container"
    , leftMenuWidth = 50
    , rightOverlayWidth = 305
    }
