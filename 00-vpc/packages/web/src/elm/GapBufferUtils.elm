module GapBufferUtils exposing (gapBufferToEnd, listToGapBuffer, stringToCharBuffer, stringToGapBuffer)

import GapBuffer exposing (GapBuffer)


gapBufferToEnd : GapBuffer a b -> GapBuffer a b
gapBufferToEnd buf =
    GapBuffer.focusAt (GapBuffer.length buf) buf


stringToGapBuffer : String -> GapBuffer String String
stringToGapBuffer val =
    String.words val
        |> GapBuffer.fromList identity (always identity)
        |> GapBuffer.focusAt 0


stringToCharBuffer : String -> GapBuffer Char Char
stringToCharBuffer val =
    String.toList val
        |> GapBuffer.fromList identity (always identity)
        |> GapBuffer.focusAt 0


listToGapBuffer : List a -> GapBuffer a a
listToGapBuffer ls =
    GapBuffer.fromList identity (always identity) ls
        |> GapBuffer.focusAt 0
