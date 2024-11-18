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
        const momentoApiKey = new sst.Secret("MomentoApiKey");

        const table = new sst.aws.Dynamo("Connections", {
            fields: {
                id: "string",
            },
            primaryIndex: {hashKey: "id"},
        });

        const api = new sst.aws.ApiGatewayV2("saveapi", {link: [momentoApiKey]});

        api.route("GET /{proxy+}",
            {
                handler: "packages/functions/src/api.main",
                link: [momentoApiKey]
            }
        );

        // Deploy the Elm app
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
            managementEndpoint: api.managementEndpoint,
            ApiEndpoint: api.url,
            SiteUrl: site.url,
        };
    },
});
