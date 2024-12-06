/// <reference path="./.sst/platform/config.d.ts" />


export default $config({
    app(input) {
        return {
            home: "aws",
            name: "00-vpc",
            removal: input.stage === "production" ? "retain" : "remove",
            providers: {
                aws: {
                    profile: input.stage === "production" ? "thesett-prod" : "thesett-dev",
                    region: "eu-west-2"
                }
            }
        };
    },
    async run() {
        // High performance serverless cache an pubsub messaging.
        const momentoApiKey = new sst.Secret("MomentoApiKey");

        // DynamoDB tables for channels and events.
        const channelTable = new sst.aws.Dynamo("ChannelTable", {
            fields: {
                id: "string"
            },
            primaryIndex: {hashKey: "id"}
        });

        const eventLogTable = new sst.aws.Dynamo("EventLogTable", {
            fields: {
                id: "string",
                seq: "number"
            },
            primaryIndex: {hashKey: "id", rangeKey: "seq"}
        });

        const snapshotTable = new sst.aws.Dynamo("SnapshotTable", {
            fields: {
                id: "string",
                seq: "number"
            },
            primaryIndex: {hashKey: "id", rangeKey: "seq"}
        });

        // API for managing the realtime channels.
        const api = new sst.aws.ApiGatewayV2("ChannelApi", {link: [momentoApiKey]});

        api.route("ANY /v1/{proxy+}",
            {
                handler: "packages/functions/src/api.main",
                link: [
                    momentoApiKey,
                    api,
                    channelTable,
                    eventLogTable,
                    snapshotTable
                ]
            }
        );

        api.route("ANY /clear",
            {
                handler: "packages/functions/src/clear.main",
                link: [momentoApiKey, channelTable, eventLogTable]
            }
        );

        // Elm UI for realtime channel management.
        const site = new sst.aws.StaticSite("ChatSite", {
            path: "packages/web",
            build: {
                command: "npm run prod",
                output: "dist",
            },
            environment: {
                CHAT_API_URL: api.url,
                MOMENTO_API_KEY: momentoApiKey.value
            },
        });

        return {
            ApiEndpoint: api.url,
            SiteUrl: site.url,
        };
    },
});
