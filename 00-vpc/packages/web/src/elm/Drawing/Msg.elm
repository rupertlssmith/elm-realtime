module Drawing.Msg exposing (GestureLocation(..), Msg(..))

import Drawing.GestureEvent exposing (GestureEvent)
import Geometry exposing (PScreen, Screen, VScreen)
import Pointer
import Time exposing (Posix)


type Msg
    = WindowSize VScreen
    | OnGestureMsg GestureLocation (Pointer.Msg GestureEvent Screen)
    | OnGestureDrag (Pointer.DragArgs Screen) GestureEvent GestureEvent
    | OnGestureDragEnd (Pointer.DragArgs Screen) GestureEvent GestureEvent
    | OnGestureTap (Pointer.PointArgs Screen) GestureEvent
    | OnGestureDoubleTap (Pointer.PointArgs Screen) GestureEvent
    | OnGestureMove PScreen GestureEvent
    | OnGestureZoom (Pointer.ScaleArgs Screen) GestureEvent
    | Tick Posix
    | Noop


type GestureLocation
    = Doc
    | Div
