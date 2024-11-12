/// <reference path="./.sst/platform/config.d.ts" />


export default $config({
    app(input) {
        return {
            home: "aws",
            //region: "eu-west-2",
            name: "00-vpc",
            removal: input.stage === "production" ? "retain" : "remove",
            //profile: input.stage === "production" ? "thesett-prod" : "thesett-dev",
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

        const api = new sst.aws.ApiGatewayWebSocket("api", {});

        api.route("$connect", {
            handler: "packages/functions/src/connect.main",
            link: [table],
            //dev: false
        });
        api.route("$disconnect", {
            handler: "packages/functions/src/disconnect.main",
            link: [table],
            //dev: false
        });
        api.route("$default", "packages/functions/src/default.main");
        api.route("sendMessage", {
            handler: "packages/functions/src/sendmessage.main",
            link: [table, api, momentoApiKey],
            //dev: false
        });

        // const httpApi = new sst.aws.ApiGatewayV2("MyApi");
        // httpApi.route("GET /", {
        //     handler: "packages/functions/src/connect.main",
        //     //dev: false
        // });

        // const fun = new sst.aws.Function("MyFunction", {
        //     handler: "packages/functions/src/connect.main",
        //     link: [table],
        //     url: true
        // });

        // Deploy the Elm app
        const site = new sst.aws.StaticSite("ChatSite", {
            path: "packages/web",
            build: {
                command: "npm run prod",
                output: "dist",
            },
            environment: {
                CHAT_API_URL: api.url,
            },
        });

        return {
            managementEndpoint: api.managementEndpoint,
            ApiEndpoint: api.url,
            SiteUrl: site.url,
        };
    },
});
