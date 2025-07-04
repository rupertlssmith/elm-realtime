# Setting up on AWS.

I have set up an AWS root account for thesett. Underneath that I have created a management account
and two other accounts, dev and prod. The set up takes a bit of effort to complete, but instructions
on how to do it can be found here: https://docs.sst.dev/setting-up-aws

My AWS config file (~/.aws/config) contains the following:

```
[sso-session thesett]
sso_start_url = https://thesett.awsapps.com/start
sso_region = us-east-1

[profile thesett-dev]
sso_session = thesett
sso_account_id = 030696475731
sso_role_name = AdministratorAccess
region = eu-west-2

[profile thesett-prod]
sso_session = thesett
sso_account_id = 933232018743
sso_role_name = AdministratorAccess
region = eu-west-2

[default]
region = eu-west-2
```

Once the above is in place, you need to install the AWS cli tools: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Then sign in to AWS SSO:

    aws sso login --sso-session=thesett

This will prompt you to log in using the management account.

If you want to create an AWS account for example for IJI, run through the above but replace thesett with iji.

# Setting up for Development

### Setting up third party services

Momento is being used for low-latency pubsub topics. Using the [Momento console](https://console.gomomento.com/), 
create an API key. For now, create an API key has full access, because it needs to be able to create a topic. 
Download this key into a JSON file. The key must be set as an sst secret.

    npx sst secret set MomentoApiKey < ./momento_secret.json

Note, this must be done separately when deploying the other stages.

    npx sst secret set --stage production MomentoApiKey < ./momento_secret.json

### To install all Node packages needed to build:

    npm ci

### To run in dev mode:

    npx sst dev &

### To recompile the Elm code for the backend during dev:

    cd packages/functions
    elm make src/API.elm --output src/elm.js

This can also be run with a file watcher that will rebuild it immediately when Elm files are edited. 

    cd packages/functions
    npx onchange '../**/*.elm' -- elm make src/API.elm --output src/elm.js

### To check that the API is working:

Replace the URL with whatever URL the ApiEndpoint comes out as on the console once dev mode has been started:

    curl -X POST https://de6pgy115l.execute-api.eu-west-2.amazonaws.com  -H 'Content-Type: application/json' -d '{"prompt":"What is so great about AI in less then 100 words."}'

### To recompile the Elm code the frontend during dev:

This happens automatically as part of running `npx sst dev`. It is configured through SST in sst.config.ts as 
below. The build command that is run to build the web application is part of this configuration:

    // Elm UI for realtime channel management.
    const site = new sst.aws.StaticSite("ChatSite", {
        path: "packages/web",
        build: {
            command: "npm run prod",
            output: "dist",
        },
        environment: {
            ELM_RT_CHANNEL_API_URL: api.url,
            MOMENTO_API_KEY: momentoApiKey.value
        },
    });


# Deploying to Production

    npx sst deploy --stage production
