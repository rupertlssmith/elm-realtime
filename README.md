# Setting up on AWS.

I have set up an AWS root account for thesett. Underneath that I have created a management account
and two other accounts, dev and prod. The set up takes a bit of effort to complete, but instructions
on how to do it can be found here: https://docs.sst.dev/setting-up-aws


Once the above is in place, you need to install the AWS cli tools: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Then sign in to AWS SSO:

    aws sso login --sso-session=your_org

This will prompt you to log in using the management account.

If you want to create an AWS account for example for IJI, run through the above but replace thesett with iji.

# Setting up for Development

# Setting up third party services

Momento is being used for low-latency pubsub topics. Using the Momento console, create an API key. For now,
create an API key has full access, because it needs to be able to create a topic. Download this key into a
JSON file. The key must be set as an sst secret.

    npx sst secret set MomentoApiKey < ./momento_secret.json

Note, this must be done separately when deploying the other stages.

    npx sst secret set --statge production MomentoApiKey < ./momento_secret.json

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

# Deploying to Production

    npx sst deploy --stage production
