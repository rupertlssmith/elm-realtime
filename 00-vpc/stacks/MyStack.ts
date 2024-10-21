import {StackContext, Api, Function, StaticSite} from "sst/constructs";

export function ChatStack({stack}: StackContext) {
    const api = new Api(stack, "api", {
        defaults: {},
        routes: {
            "POST /": {
                function: new Function(stack, "Chat", {
                    handler: "packages/functions/src/lambda.chat",
                })
            }
        }
    });

    // Deploy our React app
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
