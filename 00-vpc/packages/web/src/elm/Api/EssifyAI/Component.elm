module Api.EssifyAI.Component exposing
    ( Component
    , Model
    , Msg
    , Protocol
    , addStep
    , init
    , startConversation
    , update
    , wsMessage
    , wsOpened
    )

import Api.EssifyAI.Enum.SessionType as SessionType exposing (SessionType(..))
import Api.EssifyAI.InputObject as InputObject
import Api.EssifyAI.Mutation as Mutation
import Api.EssifyAI.Object exposing (ApiToken(..))
import Api.EssifyAI.Object.AddConversationStepPayload as AddConversationStepPayload
import Api.EssifyAI.Object.ApiToken as ApiToken
import Api.EssifyAI.Object.ArbitraryPipelineTracePayload as ArbitraryPipelineTracePayload
import Api.EssifyAI.Object.AuthenticatePayload as AuthenticatePayload
import Api.EssifyAI.Object.Conversation as Conversation
import Api.EssifyAI.Object.ConversationConnection as ConversationConnection
import Api.EssifyAI.Object.ConversationEdge as ConversationEdge
import Api.EssifyAI.Object.ConversationStep as ConversationStep
import Api.EssifyAI.Object.CreateConversationPayload as CreateConversationPayload
import Api.EssifyAI.Object.Dataroom as Dataroom
import Api.EssifyAI.Object.DataroomConnection as DataroomConnection
import Api.EssifyAI.Object.DataroomEdge as DataroomEdge
import Api.EssifyAI.Object.PipelineTrace as PipelineTrace
import Api.EssifyAI.Object.PipelineTraceConnection as PipelineTraceConnection
import Api.EssifyAI.Object.PipelineTraceEdge as PipelineTraceEdge
import Api.EssifyAI.Object.Session as Session
import Api.EssifyAI.Object.User as User
import Api.EssifyAI.Query as Query
import Api.EssifyAI.Subscription as Subscription
import Api.EssifyAI.Union.PipelineTracePayload as PipelineTracePayload
import Domain.Conversation exposing (Step)
import Graphql.Document
import Graphql.Http
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as DE
import Json.Encode as Encode exposing (Value)
import Update2 as U2


type alias Component a =
    { a
        | essifyAI : Model
    }


type Model
    = ModelStart StartState
    | ModelAuthenticated AuthenticatedState
    | ModelFetchedUser FetchedUserState
    | ModelStartedConversation StartedConversationState
    | ModelConnected ConnectedState
    | ModelConnectionAcked ConnectedState


type alias StartState =
    { url : String }


type alias AuthenticatedState =
    { url : String
    , auth : AuthenticationResult
    }


type alias FetchedUserState =
    { url : String
    , auth : AuthenticationResult
    , me : User
    }


type alias StartedConversationState =
    { url : String
    , auth : AuthenticationResult
    , me : User
    , convId : String
    , convToken : String
    }


type alias ConnectedState =
    { url : String
    , auth : AuthenticationResult
    , me : User
    , convId : String
    , convToken : String
    }


switchState : (a -> Model) -> a -> ( Model, Cmd Msg )
switchState cons state =
    ( cons state
    , Cmd.none
    )


type alias DataroomAccess =
    { apiToken : String
    , dataroomId : String
    }


type alias AuthenticationResult =
    { bearerToken : String
    }


type alias User =
    { id : String
    , email : String
    , fullName : String
    , datarooms : List Dataroom
    , conversations : List ConversationSummary
    , apiTokenName : String
    , apiToken : String
    }


type alias Session =
    { sessionType : SessionType.SessionType
    , bearerToken : String
    }


type alias Dataroom =
    { id : String
    , title : String
    , description : String
    }


type alias ConversationSummary =
    { id : String
    , title : String
    }


type alias ConversationStep =
    { id : String
    , userInput : String
    , traces : List Trace
    }


type alias Trace =
    { id : String
    , success : Bool
    , logs : String
    , payload : Value
    }


type Msg
    = Authenticated AuthenticationResult
    | FetchedUser User
    | StartedConversation ( String, String )
    | AddedStep ConversationStep
    | ApiError


init : (Msg -> msg) -> () -> ( Model, Cmd msg )
init toMsg flags =
    { url = "http://localhost:4001/api/graphiql"
    }
        |> U2.pure
        |> U2.andMap authenticate
        |> U2.andMap (switchState ModelStart)
        |> Tuple.mapSecond (Cmd.map toMsg)


responseHandler : (decodesTo -> Msg) -> (Result (Graphql.Http.Error decodesTo) decodesTo -> Msg)
responseHandler okRespFn res =
    case res of
        Ok val ->
            okRespFn val

        Err err ->
            let
                _ =
                    Debug.log "Err" err
            in
            ApiError


type alias Protocol submodel msg model =
    { toMsg : Msg -> msg
    , onUpdate : ( submodel, Cmd msg ) -> ( model, Cmd msg )

    -- Websocket interface.
    , wsOpen : String -> String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , wsSend : String -> String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )

    -- Conversation interface.
    , onConversationReady : String -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    , onStepAdded : String -> Step -> ( submodel, Cmd msg ) -> ( model, Cmd msg )
    }



--startConversation : Protocol (Component a) msg model -> Component a -> ( model, Cmd msg )
--userStep : Protocol (Component a) msg model -> String -> String -> Component a -> ( model, Cmd msg )


update : Protocol (Component a) msg model -> Msg -> Component a -> ( model, Cmd msg )
update protocol msg component =
    let
        model =
            component.essifyAI

        setModel m x =
            { m | essifyAI = x }
    in
    case ( model, Debug.log "update" msg ) of
        ( ModelStart state, Authenticated auth ) ->
            U2.pure
                { url = state.url
                , auth = auth
                }
                |> U2.andThen fetchUser
                |> U2.andMap (switchState ModelAuthenticated)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelAuthenticated state, FetchedUser me ) ->
            U2.pure
                { url = state.url
                , auth = state.auth
                , me = me
                }
                |> U2.andThen startConversation
                |> U2.andMap (switchState ModelFetchedUser)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.onUpdate

        ( ModelFetchedUser state, StartedConversation ( convId, convToken ) ) ->
            U2.pure
                { url = state.url
                , auth = state.auth
                , me = state.me
                , convId = convId
                , convToken = convToken
                }
                |> U2.andMap (switchState ModelStartedConversation)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.wsOpen "id" "ws://localhost:4001/ws/graphql"

        ( ModelConnectionAcked _, AddedStep _ ) ->
            U2.pure component
                |> protocol.onUpdate

        _ ->
            U2.pure component
                |> protocol.onUpdate


wsOpened : Protocol (Component a) msg model -> String -> Component a -> ( model, Cmd msg )
wsOpened protocol id component =
    let
        model =
            component.essifyAI

        setModel m x =
            { m | essifyAI = x }

        _ =
            Debug.log "wsOpened" id
    in
    case model of
        ModelStartedConversation state ->
            let
                --payload =
                --    [ ( "user", Encode.string state.me.id )
                --    , ( "session", Encode.string state.auth.bearerToken )
                --    , ( "api_token", Encode.string state.me.apiToken )
                --    ]
                --        |> Encode.object
                connectionInitMsg =
                    --{ payload = Just payload }
                    { payload = Nothing }
                        |> encodeConnectionInit
                        |> Encode.encode 0
            in
            U2.pure state
                |> U2.andMap (switchState ModelConnected)
                |> Tuple.mapFirst (setModel component)
                |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                |> protocol.wsSend "id" connectionInitMsg

        _ ->
            U2.pure component
                |> protocol.onUpdate


wsMessage : Protocol (Component a) msg model -> String -> String -> Component a -> ( model, Cmd msg )
wsMessage protocol id payload component =
    let
        model =
            component.essifyAI

        setModel m x =
            { m | essifyAI = x }

        _ =
            Debug.log "wsMessage" ( id, payload )
    in
    case Decode.decodeString graphqlWsDecoder payload of
        Ok msg ->
            case ( model, Debug.log "wsMessage" msg ) of
                ( ModelConnected state, ConnectionAck _ ) ->
                    let
                        arbitraryTraceQuery =
                            SelectionSet.succeed
                                (\traceId subtype data ->
                                    [ ( "id", Encode.string traceId )
                                    , ( "subtype", Encode.string subtype )
                                    , ( "data", data )
                                    ]
                                        |> Encode.object
                                )
                                |> SelectionSet.with ArbitraryPipelineTracePayload.id
                                |> SelectionSet.with ArbitraryPipelineTracePayload.subtype
                                |> SelectionSet.with ArbitraryPipelineTracePayload.data

                        pipelineTraceQuery =
                            PipelineTracePayload.fragments
                                { onArbitraryPipelineTracePayload = arbitraryTraceQuery
                                , onKnowledgeGraphPipelineTracePayload = SelectionSet.succeed (Encode.string "knowledgegraph")
                                , onLlmQueryPipelineTracePayload = SelectionSet.succeed (Encode.string "llm")
                                , onVectorsPipelineTracePayload = SelectionSet.succeed (Encode.string "vectors")
                                }
                                |> PipelineTrace.payload

                        traceFragment =
                            SelectionSet.succeed Trace
                                |> SelectionSet.with PipelineTrace.id
                                |> SelectionSet.with PipelineTrace.success
                                |> SelectionSet.with PipelineTrace.logs
                                |> SelectionSet.with pipelineTraceQuery

                        tracesQuery =
                            traceFragment
                                |> paginationReducer PipelineTraceEdge.node PipelineTraceConnection.edges
                                |> ConversationStep.traces
                                    (\args ->
                                        { args
                                            | first = Present 10
                                        }
                                    )
                                |> SelectionSet.withDefault []

                        query =
                            SelectionSet.succeed
                                (\stepId content traces ->
                                    { id = stepId
                                    , content = content
                                    , traces = traces
                                    }
                                )
                                |> SelectionSet.with ConversationStep.id
                                |> SelectionSet.with ConversationStep.content
                                |> SelectionSet.with tracesQuery

                        subscription =
                            Subscription.conversationStepCreated
                                { bearerToken = state.convToken
                                , id = state.convId
                                }
                                query
                                |> Graphql.Document.serializeSubscription

                        subscriptionMsg =
                            { id = "sub1"
                            , payload = { query = subscription }
                            }
                                |> encodeSubscribe
                                |> Encode.encode 0
                    in
                    U2.pure state
                        |> U2.andThen addStep
                        |> U2.andMap (switchState ModelConnectionAcked)
                        |> Tuple.mapFirst (setModel component)
                        |> Tuple.mapSecond (Cmd.map protocol.toMsg)
                        |> protocol.wsSend "id" subscriptionMsg

                _ ->
                    U2.pure component
                        |> protocol.onUpdate

        Err _ ->
            U2.pure component
                |> protocol.onUpdate


authenticate : StartState -> ( StartState, Cmd Msg )
authenticate model =
    let
        input =
            InputObject.buildAuthenticateInput
                { email = "user1@essify.ai"
                , password = "A V3ry S3cure P4ssw0rD!"
                }

        query =
            SelectionSet.succeed AuthenticationResult
                |> SelectionSet.with Session.bearerToken
                |> AuthenticatePayload.session

        mutation =
            Mutation.authenticate
                { input = input }
                query
                |> SelectionSet.nonNullOrFail

        request =
            mutation
                |> Graphql.Http.mutationRequest model.url
                |> Graphql.Http.withOperationName "Authenticate"
    in
    ( model
    , Graphql.Http.send (responseHandler Authenticated) request
    )


fetchUser : AuthenticatedState -> ( AuthenticatedState, Cmd Msg )
fetchUser model =
    let
        dataroomFragment : SelectionSet.SelectionSet Dataroom Api.EssifyAI.Object.Dataroom
        dataroomFragment =
            SelectionSet.succeed Dataroom
                |> SelectionSet.with Dataroom.id
                |> SelectionSet.with Dataroom.title
                |> SelectionSet.with Dataroom.description

        dataroomsQuery : SelectionSet.SelectionSet (List Dataroom) Api.EssifyAI.Object.User
        dataroomsQuery =
            dataroomFragment
                |> paginationReducer DataroomEdge.node DataroomConnection.edges
                |> User.datarooms
                    (\args ->
                        { args
                            | first = Present 10
                        }
                    )
                |> SelectionSet.withDefault []

        conversationFragment : SelectionSet.SelectionSet ConversationSummary Api.EssifyAI.Object.Conversation
        conversationFragment =
            SelectionSet.succeed ConversationSummary
                |> SelectionSet.with Conversation.id
                |> SelectionSet.with Conversation.title

        conversationsQuery : SelectionSet.SelectionSet (List ConversationSummary) Api.EssifyAI.Object.User
        conversationsQuery =
            conversationFragment
                |> paginationReducer ConversationEdge.node ConversationConnection.edges
                |> User.conversations
                    (\args ->
                        { args
                            | first = Present 10
                        }
                    )
                |> SelectionSet.withDefault []

        apiTokenFragment : SelectionSet ( String, String ) Api.EssifyAI.Object.User
        apiTokenFragment =
            SelectionSet.succeed Tuple.pair
                |> SelectionSet.with ApiToken.name
                |> SelectionSet.with ApiToken.token
                |> User.defaultApiToken

        query =
            SelectionSet.succeed
                (\id email fullName ( apiTokenName, apiToken ) datarooms conversations ->
                    { id = id
                    , email = email
                    , fullName = fullName
                    , datarooms = datarooms
                    , conversations = conversations
                    , apiTokenName = apiTokenName
                    , apiToken = apiToken
                    }
                )
                |> SelectionSet.with User.id
                |> SelectionSet.with User.email
                |> SelectionSet.with User.fullName
                |> SelectionSet.with apiTokenFragment
                |> SelectionSet.with dataroomsQuery
                |> SelectionSet.with conversationsQuery
                |> Query.me

        request =
            query
                |> Graphql.Http.queryRequest model.url
                |> Graphql.Http.withOperationName "Me"
                |> addAuthorization model.auth.bearerToken
    in
    ( model
    , Graphql.Http.send (responseHandler FetchedUser) request
    )


startConversation : FetchedUserState -> ( FetchedUserState, Cmd Msg )
startConversation model =
    case List.head model.me.datarooms of
        Just { id } ->
            let
                input =
                    InputObject.buildCreateConversationInput
                        { attrs =
                            { title = "Conversation Title"

                            -- data: Just trying this, can be Absent or Null
                            , data =
                                [ ( "teamspace_user_id", Encode.int 32 ) ]
                                    |> Encode.object
                                    |> Encode.encode 0
                                    |> Encode.string
                                    |> Present
                            }
                        , dataroomId = id
                        }
                        identity

                subjectQuery =
                    SelectionSet.succeed (\x _ -> x)
                        |> SelectionSet.with Conversation.id
                        |> SelectionSet.with Conversation.title
                        |> CreateConversationPayload.subject

                tokenQuery =
                    CreateConversationPayload.bearerToken

                query =
                    SelectionSet.succeed Tuple.pair
                        |> SelectionSet.with subjectQuery
                        |> SelectionSet.with tokenQuery

                --|> Query.me
                mutation =
                    Mutation.createConversation
                        { input = input }
                        query
                        |> SelectionSet.nonNullOrFail

                request =
                    mutation
                        |> Graphql.Http.mutationRequest model.url
                        |> Graphql.Http.withOperationName "CreateConversation"
                        |> addAuthorization model.me.apiToken
            in
            ( model
            , Graphql.Http.send (responseHandler StartedConversation) request
            )

        Nothing ->
            U2.pure model


addStep : ConnectedState -> ( ConnectedState, Cmd Msg )
addStep model =
    let
        input =
            InputObject.buildAddConversationStepInput
                { attrs =
                    { content = "What tips on working with Scrum do you have?"
                    , data = Absent
                    }
                , conversationId = model.convId
                }

        query =
            SelectionSet.succeed ConversationStep
                |> SelectionSet.with ConversationStep.id
                |> SelectionSet.with ConversationStep.content
                |> SelectionSet.with (SelectionSet.succeed [])
                |> AddConversationStepPayload.subject

        mutation =
            Mutation.addConversationStep
                { input = input }
                query
                |> SelectionSet.nonNullOrFail

        request =
            mutation
                |> Graphql.Http.mutationRequest model.url
                |> Graphql.Http.withOperationName "AddConversationStep"
                |> addAuthorization model.convToken
    in
    ( model
    , Graphql.Http.send (responseHandler AddedStep) request
    )


addAuthorization bearerToken req =
    Graphql.Http.withHeader "Authorization" ("Bearer " ++ bearerToken) req


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions toMsg model =
    Sub.none



--view : (Msg -> msg) -> Model -> Html msg
--view toMsg model =
--    let
--        prettyDebug =
--            Debug.toString >> String.split "," >> String.join "\n," >> Html.text
--    in
--    [ Maybe.map prettyDebug model.auth
--    , Maybe.map prettyDebug model.me
--    ]
--        |> List.filterMap identity
--        |> List.intersperse (Html.br [] [])
--        |> Html.pre []
-- Helpers


{-| Squashes `edges { node { x } }` to `List x`.
-}
paginationReducer :
    (SelectionSet.SelectionSet a1 scope2 -> SelectionSet.SelectionSet (Maybe a2) scope1)
    ->
        (SelectionSet.SelectionSet (List a2) scope1
         -> SelectionSet.SelectionSet (Maybe (List (Maybe (List a)))) scope
        )
    -> SelectionSet.SelectionSet a1 scope2
    -> SelectionSet.SelectionSet (List a) scope
paginationReducer node edges val =
    val
        |> node
        |> SelectionSet.map (Maybe.map List.singleton)
        |> SelectionSet.withDefault []
        |> edges
        |> SelectionSet.withDefault []
        |> SelectionSet.map (List.filterMap identity)
        |> SelectionSet.map List.concat



-- Graphql-ws


type GraphqlWs
    = ConnectionInit ConnectionInitProps
    | ConnectionAck ConnectionAckProps
    | Subscribe SubscribeProps


graphqlWsDecoder : Decoder GraphqlWs
graphqlWsDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\type_ ->
                case type_ of
                    "connection_ack" ->
                        connectionAckDecoder
                            |> Decode.map ConnectionAck

                    _ ->
                        Decode.fail "uknown"
            )


type alias SubscribeProps =
    { id : String
    , payload : PayloadProps
    }


type alias PayloadProps =
    { query : String }


encodeSubscribe : SubscribeProps -> Value
encodeSubscribe val =
    [ ( "type", Encode.string "subscribe" )
    , ( "id", Encode.string val.id )
    , ( "payload", encodePayload val.payload )
    ]
        |> Encode.object


encodePayload : PayloadProps -> Value
encodePayload val =
    [ ( "query", Encode.string val.query ) ]
        |> Encode.object


type alias ConnectionInitProps =
    { payload : Maybe Value
    }


encodeConnectionInit : ConnectionInitProps -> Value
encodeConnectionInit val =
    [ ( "type", Encode.string "connection_init" ) |> Just
    , Maybe.map (\pl -> ( "payload", pl )) val.payload
    ]
        |> List.filterMap identity
        |> Encode.object


type alias ConnectionAckProps =
    { payload : Maybe Value
    }


connectionAckDecoder : Decoder ConnectionAckProps
connectionAckDecoder =
    Decode.succeed ConnectionAckProps
        |> DE.andMap (Decode.field "payload" Decode.value |> Decode.maybe)



--|> protocol.wsSend "id" "{\"type\": \"ping\"}"
