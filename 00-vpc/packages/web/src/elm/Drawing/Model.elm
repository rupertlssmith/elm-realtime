module Drawing.Model exposing (Model(..))

import Drawing.Scene.Spec exposing (Scene)


type Model
    = SizingWindow
    | Ready Scene
