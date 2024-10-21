module Drawing.Scene.Spec exposing (Entity(..), EntityCons, EntityIF, EntityId, Scene(..), SceneCons, SceneIF, UpdateContext(..), UpdateContextCons, UpdateContextIF, ViewContextIF, entity, scene, updateContext)

import AdHoc as AH
import Animate exposing (Timeline)
import Camera2d exposing (Camera2d)
import Drawing.Msg exposing (Msg)
import Geometry exposing (BLocal, BScreen, PScene, PScreen, Screen, VScene, VScreen)
import Html.Styled exposing (Html)
import Pixels exposing (Pixels)
import Quantity exposing (Unitless)
import Time exposing (Posix)
import TypedSvg.Core exposing (Svg)


{-| All Entities have unique identifiers within the Scene.
-}
type alias EntityId =
    String


{-| The Scene describes the interface through which it can be updated.
-}
type Scene
    = Scene SceneIF


type alias SceneIF =
    { subscriptions : Sub Msg
    , update : Msg -> ( Scene, Cmd Msg )
    , view : () -> Html Msg
    , add : EntityId -> Entity Msg -> Scene
    }


type alias SceneCons rep =
    { subscriptions : rep -> Sub Msg
    , update : Msg -> rep -> (rep -> Scene) -> ( Scene, Cmd Msg )
    , view : rep -> Html Msg
    , add : EntityId -> Entity Msg -> rep -> rep
    }


scene : SceneCons rep -> rep -> Scene
scene cons =
    AH.impl SceneIF
        |> AH.add (\rep -> cons.subscriptions rep)
        |> AH.wrap
            (\raise rep msg ->
                cons.update msg rep raise
             -- |> Tuple.mapFirst raise
            )
        |> AH.add (\rep () -> cons.view rep)
        |> AH.wrap (\raise rep id e -> cons.add id e rep |> raise)
        |> AH.map Scene
        |> AH.init (\raise rep -> raise rep)


{-| The UpdateContextIF provides a context for updates to an Entity, to tell it about the
side effects or state changes it can make to the Scene.

This consists of :

  - The set of side effects available.
  - Properties of the context, such as size and position etc.
  - Functions to apply changes to properties that are editable by the Entity.

-}
type UpdateContext msg
    = UpdateContext (UpdateContextIF msg)


type alias UpdateContextIF msg =
    { frame : BScreen
    , camera : Timeline (Camera2d Unitless Pixels Geometry.Scene)
    , moveCamera : VScene -> UpdateContext msg
    , zoomToBox : PScene -> BLocal -> Float -> UpdateContext msg
    , updateEntity : EntityId -> Entity msg -> UpdateContext msg
    , toScene : Scene
    }


type alias UpdateContextCons rep msg =
    { frame : rep -> BScreen
    , camera : rep -> Timeline (Camera2d Unitless Pixels Geometry.Scene)
    , moveCamera : VScene -> rep -> rep
    , zoomToBox : PScene -> BLocal -> Float -> rep -> rep
    , updateEntity : EntityId -> Entity msg -> rep -> rep
    , toScene : rep -> Scene
    }


updateContext : UpdateContextCons rep msg -> rep -> UpdateContext msg
updateContext cons =
    AH.impl UpdateContextIF
        |> AH.add (\rep -> cons.frame rep)
        |> AH.add (\rep -> cons.camera rep)
        |> AH.wrap (\raise rep vscene -> cons.moveCamera vscene rep |> raise)
        |> AH.wrap (\raise rep pos bbox scale -> cons.zoomToBox pos bbox scale rep |> raise)
        |> AH.wrap (\raise rep eid e -> cons.updateEntity eid e rep |> raise)
        |> AH.add (\rep -> cons.toScene rep)
        |> AH.map UpdateContext
        |> AH.init (\raise rep -> raise rep)


ucAndThen : (UpdateContextIF msg -> UpdateContext msg) -> UpdateContext msg -> UpdateContext msg
ucAndThen fn (UpdateContext uc) =
    fn uc


updateEntity : EntityId -> Entity msg -> UpdateContextIF msg -> UpdateContext msg
updateEntity id e ucIf =
    ucIf.updateEntity id e


{-| The ViewContextIF provides a view context to an Entity, to tell it about the
environment it is being rendered in.

This consists of :

  - The set of side effects available.
  - Properties of the context, such as size and position etc.

-}
type alias ViewContextIF msg =
    { noop : msg
    , zoom : Float
    , frame : BScreen
    , mousePos : PScreen
    , camera : Camera2d Unitless Pixels Geometry.Scene
    }


{-| An Entity models an element of the UI, and describes the interface through
which its properties can be examined and its state modified.
-}
type Entity msg
    = Entity (EntityIF msg)


type alias EntityIF msg =
    { move : VScene -> UpdateContext msg -> UpdateContext msg
    , select : UpdateContext msg -> UpdateContext msg
    , animate : Posix -> Maybe (Entity msg)
    , position : PScene
    , bbox : BLocal
    , view : ViewContextIF msg -> List (Svg msg)
    }


type alias EntityCons msg rep =
    { move : VScene -> rep -> (rep -> Entity msg) -> UpdateContext msg -> UpdateContext msg
    , select : rep -> (rep -> Entity msg) -> UpdateContext msg -> UpdateContext msg
    , animate : Posix -> rep -> Maybe rep
    , position : rep -> PScene
    , bbox : rep -> BLocal
    , view : ViewContextIF msg -> rep -> List (Svg msg)
    }


entity : EntityCons msg rep -> rep -> Entity msg
entity cons =
    AH.impl EntityIF
        |> AH.wrap (\raise rep vec uc -> cons.move vec rep raise uc)
        |> AH.wrap (\raise rep uc -> cons.select rep raise uc)
        |> AH.wrap (\raise rep posix -> cons.animate posix rep |> Maybe.map raise)
        |> AH.add (\rep -> cons.position rep)
        |> AH.add (\rep -> cons.bbox rep)
        |> AH.add (\rep actions -> cons.view actions rep)
        |> AH.map Entity
        |> AH.init (\raise rep -> raise rep)
