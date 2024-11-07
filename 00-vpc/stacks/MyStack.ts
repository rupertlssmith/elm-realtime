import {StackContext, Table, StaticSite, WebSocketApi} from "sst/constructs";

export function ChatStack({stack}: StackContext) {
    const table = new Table(stack, "Connections", {
        fields: {
            id: "string",
        },
        primaryIndex: {partitionKey: "id"},
    });

    const api = new WebSocketApi(stack, "api", {
        cdk: {
            webSocketApi: {
                routeSelectionExpression: "$request.body.topic"
            }
        },
        defaults: {
            function: {
                bind: [table],
            },
        },
        routes: {
            $connect: "packages/functions/src/connect.main",
            $disconnect: "packages/functions/src/disconnect.main",
            $default: "packages/functions/src/default.main",
            sendMessage: "packages/functions/src/sendmessage.main",
        },
    });

    // Deploy the Elm app
    const site = new StaticSite(stack, "ChatSite", {
        path: "packages/web",
        buildCommand: "npm run prod",
        buildOutput: "dist",
        environment: {
            CHAT_API_URL: api.url,
        },
    });

    stack.addOutputs({
        SiteUrl: site.url,
        ApiEndpoint: api.url,
    });
}
