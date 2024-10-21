module IntelligentAgent.DecisionTree exposing (BodyOrChild(..), DecisionTree, example)

{-| TODO: This moves to the back end. A tree is a graph and we will be using a graph database, so put the
decision tree in the graph database.
-}

import Array
import Dict exposing (Dict)
import GapBuffer exposing (GapBuffer)
import GapBufferUtils as GBU
import IntelligentAgent.ChatStep as ChatStep exposing (Block(..), Inline(..), Item, ItemOrigin(..))
import List.Extra
import Parser as P exposing ((|.), (|=), Parser)
import StringTrie exposing (Trie)


type alias DecisionTree =
    Dict String Item


empty : DecisionTree
empty =
    Dict.empty


example : DecisionTree
example =
    Dict.empty
        |> Dict.insert "intro"
            { title = "Scrum AI"
            , body =
                [ [ """Hi, I am an intelligent agent than can help you explore Scrum using Essence.
                       What would you like to know?"""
                        |> GBU.stringToGapBuffer
                        |> Text
                  ]
                    |> GBU.listToGapBuffer
                    |> Body
                ]
                    |> GBU.listToGapBuffer
            , origin = OriginAssistant
            }


dtParser : Parser DecisionTree
dtParser =
    P.succeed identity
        |. P.symbol "#"
        |. P.spaces
        |= ((\( accumSection, accumDt, accumKeys ) ->
                P.oneOf
                    [ P.succeed (\( nextSection, nextDt, nextKeys ) -> ( Just nextSection, nextDt, nextKeys ))
                        |= itemParser accumSection accumDt accumKeys
                        |> P.map P.Loop
                    , P.succeed ()
                        |> P.map
                            (\_ ->
                                P.Done ( accumDt, accumKeys )
                            )
                    ]
            )
                |> P.loop ( Nothing, empty, keyLookup )
                |> P.map Tuple.first
           )


itemParser :
    Maybe String
    -> DecisionTree
    -> Dict String ( String, List Int )
    -> Parser ( String, DecisionTree, Dict String ( String, List Int ) )
itemParser maybeSection accumDt accumKeys =
    P.succeed
        (\title bodyAndChildren ->
            let
                children =
                    bodyAndChildren
                        |> List.filterMap
                            (\bc ->
                                case bc of
                                    ParsedChild x ->
                                        Just x

                                    _ ->
                                        Nothing
                            )

                titleSlug =
                    slugify title

                ( itemKey, itemLvl ) =
                    Dict.get titleSlug accumKeys
                        |> Maybe.withDefault ( titleSlug, [] )

                currentSection =
                    maybeSection |> Maybe.withDefault titleSlug

                ( keysWithChildren, dtWithChildren ) =
                    List.foldr
                        (\( lvl, childTitle, childTagline ) ( accKey, accDt ) ->
                            let
                                childTitleSlug =
                                    slugify childTitle

                                childKey =
                                    slugifyLevel currentSection lvl childTitle

                                grandChildren =
                                    children
                                        |> List.filterMap
                                            (\( innerLvl, innerTitle, _ ) ->
                                                case List.Extra.stripPrefix lvl innerLvl of
                                                    Just [ _ ] ->
                                                        slugifyLevel currentSection innerLvl innerTitle
                                                            |> Just

                                                    _ ->
                                                        Nothing
                                            )

                                childItem =
                                    { title = childTitle
                                    , body =
                                        [ textToInlines childTagline |> GBU.listToGapBuffer |> Body ]
                                            ++ (grandChildren |> List.map Child)
                                            |> GBU.listToGapBuffer
                                    , origin = OriginAssistant
                                    }
                            in
                            ( Dict.insert childTitleSlug ( childKey, lvl ) accKey
                            , Dict.insert childKey childItem accDt
                            )
                        )
                        ( accumKeys, accumDt )
                        children

                body =
                    bodyAndChildren
                        |> List.filterMap
                            (\bc ->
                                case bc of
                                    ParsedChild ( lvl, childTitle, _ ) ->
                                        case List.Extra.stripPrefix itemLvl lvl of
                                            Just [ _ ] ->
                                                slugifyLevel currentSection lvl childTitle |> Child |> Just

                                            _ ->
                                                Nothing

                                    ParsedBody b ->
                                        b |> textToInlines |> GBU.listToGapBuffer |> Body |> Just
                            )
                        |> GBU.listToGapBuffer

                currentDt =
                    Dict.insert
                        itemKey
                        { title = title
                        , body = body
                        , origin = OriginAssistant
                        }
                        dtWithChildren
            in
            ( currentSection, currentDt, keysWithChildren )
        )
        |= P.getChompedString (P.chompUntil "\n")
        |. P.symbol "\n"
        |= bodyAndChildParser


type BodyOrChild
    = ParsedBody String
    | ParsedChild ( List Int, String, String )


bodyAndChildParser : Parser (List BodyOrChild)
bodyAndChildParser =
    (\revChildren ->
        P.oneOf
            [ P.succeed ()
                |. P.symbol "#"
                |. P.spaces
                |> P.map (\_ -> List.reverse revChildren |> P.Done)
            , P.succeed (\lvl ( title, tagline ) -> P.Loop ((( lvl, title, tagline ) |> ParsedChild) :: revChildren))
                |= lvlParser
                |. P.spaces
                |= childParser
                |. P.chompWhile ((==) '\n')
            , P.succeed (\text -> P.Loop (ParsedBody text :: revChildren))
                |= bodyParser
                |. P.chompWhile ((==) '\n')
            , P.succeed ()
                |> P.map (\_ -> List.reverse revChildren |> P.Done)
            ]
    )
        |> P.loop []


bodyParser : Parser String
bodyParser =
    P.succeed identity
        |= P.getChompedString (P.chompUntil "\n")
        |. P.symbol "\n"


childParser : Parser ( String, String )
childParser =
    P.succeed
        (\line ->
            let
                splits =
                    String.split ": " line
            in
            ( List.head splits |> Maybe.withDefault ""
            , List.tail splits |> Maybe.withDefault [] |> String.join ": "
            )
        )
        |= P.getChompedString (P.chompUntil "\n")
        |. P.symbol "\n"


lvlParser : Parser (List Int)
lvlParser =
    P.sequence
        { start = ""
        , separator = "."
        , end = ""
        , spaces = P.spaces
        , item = pureInt
        , trailing = P.Forbidden
        }
        |> P.andThen
            (\lvl ->
                case lvl of
                    [] ->
                        P.problem "empty level"

                    _ ->
                        P.succeed lvl
            )


pureInt : Parser Int
pureInt =
    P.getChompedString (P.chompWhile Char.isDigit)
        |> P.andThen
            (\s ->
                String.toInt s
                    |> Maybe.map (\i -> P.succeed i)
                    |> Maybe.withDefault (P.problem "Parsed int not an int!")
            )


runParser : Parser DecisionTree -> String -> DecisionTree
runParser parser data =
    P.run parser data
        |> Result.withDefault empty


{-| Scans a string for tokens by name. Matches are converted to Element, and the text is converted to Text.
-}
textToInlines : String -> List Inline
textToInlines body =
    let
        charBuffer =
            GBU.stringToCharBuffer body

        scanTokenFromPos pos =
            StringTrie.match
                (\maybeChar maybeUUID ctxIdx acc ->
                    case maybeUUID of
                        Just uuid ->
                            ( ( pos, ctxIdx, uuid ) |> Just
                            , ctxIdx
                            , StringTrie.break
                            )

                        Nothing ->
                            case maybeChar of
                                Nothing ->
                                    ( acc, ctxIdx, StringTrie.wildcard )

                                Just nextTokenChar ->
                                    let
                                        charsMatch =
                                            GapBuffer.get ctxIdx charBuffer
                                                |> Maybe.map ((==) nextTokenChar)
                                                |> Maybe.withDefault False
                                    in
                                    case ( charsMatch, GapBuffer.get (ctxIdx + 1) charBuffer ) of
                                        ( True, Just nextBufferChar ) ->
                                            ( acc, ctxIdx + 1, StringTrie.continueIf nextBufferChar )

                                        ( False, Just _ ) ->
                                            ( acc, ctxIdx, StringTrie.break )

                                        ( _, Nothing ) ->
                                            ( acc, ctxIdx, StringTrie.break )
                )
                Nothing
                pos
                tokenLookup

        scanBuffer pos acc =
            let
                ( nextAcc, nextInc ) =
                    scanTokenFromPos pos
                        |> Maybe.map
                            (\( start, end, uuid ) ->
                                ( ( start, end, uuid ) :: acc, end - start + 1 )
                            )
                        |> Maybe.withDefault ( acc, 1 )
            in
            if (pos + nextInc) >= GapBuffer.length charBuffer then
                nextAcc

            else
                scanBuffer (pos + nextInc) nextAcc

        tokenMatches =
            scanBuffer 0 []
                |> List.reverse

        ( endIdx, textAndTokens ) =
            List.foldl
                (\( start, end, uuid ) ( idx, acc ) ->
                    ( end + 1
                    , Element uuid
                        :: (GapBuffer.slice idx start charBuffer
                                |> Array.toList
                                |> String.fromList
                                |> GBU.stringToGapBuffer
                                |> Text
                           )
                        :: acc
                    )
                )
                ( 0, [] )
                tokenMatches
    in
    if endIdx >= GapBuffer.length charBuffer then
        List.reverse textAndTokens

    else
        (GapBuffer.slice endIdx (GapBuffer.length charBuffer) charBuffer
            |> Array.toList
            |> String.fromList
            |> GBU.stringToGapBuffer
            |> Text
        )
            :: textAndTokens
            |> List.reverse


tokenLookup : Trie String
tokenLookup =
    [ ( "Sprint Review", "fc049630-f98f-4118-862e-a483380ef1ba" )
    , ( "Product Backlog Refinement", "91f47b0c-fc87-4073-83bc-d74ed03f4ce4" )
    , ( "Daily Scrum", "3c0c5555-231b-4cef-9918-be9f90ab64af" )
    , ( "Sprint Planning", "8d1a68f7-2145-4fb0-a521-44b10f42b578" )
    , ( "Sprint Retrospective", "3db66e37-f278-4542-b556-5e274000f680" )
    , ( "Stakeholders", "6c38cf33-dd35-530e-81ac-4bb5e6f57f59" )
    , ( "Product Backlog Item", "1b524787-204f-4791-97b2-4216e16f7174" )
    , ( "Developers", "05e9652c-6b2a-4846-862b-a1e7930c809a" )
    , ( "Sprint Backlog", "1f24ac1b-ab51-4226-9eed-cad800abd23b" )
    ]
        |> List.foldl
            (\( k, v ) acc -> StringTrie.insert k v acc)
            StringTrie.empty


keyLookup : Dict String ( String, List Int )
keyLookup =
    [ ( "sprint-review", ( "fc049630-f98f-4118-862e-a483380ef1ba", [] ) )
    , ( "product-backlog-refinement", ( "91f47b0c-fc87-4073-83bc-d74ed03f4ce4", [] ) )
    , ( "daily-scrum", ( "3c0c5555-231b-4cef-9918-be9f90ab64af", [] ) )
    , ( "sprint-planning", ( "8d1a68f7-2145-4fb0-a521-44b10f42b578", [] ) )
    , ( "sprint-retrospective", ( "3db66e37-f278-4542-b556-5e274000f680", [] ) )
    ]
        |> Dict.fromList


slugify : String -> String
slugify val =
    String.toLower val
        |> String.words
        |> String.join "-"


slugifyLevel : String -> List Int -> String -> String
slugifyLevel section lvl val =
    (String.toLower section |> String.words)
        ++ ((List.map String.fromInt lvl |> String.join ".")
                :: (String.toLower val |> String.words)
           )
        |> String.join "-"
