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

### To install all Node packages needed to build:

    cd 00-vpc
    npm ci
    cd packages/web
    npm ci

### To set up a Python virtual environment (you will need python installed already):

    cd 00-vpc
    python3 -m venv venv
    . ./venv/bin/activate
    pip install -r packages/functions/requirements.txt

### To run in dev mode

    cd 00-vpc
    npx sst dev &
    cd packages/web
    npm start

### To check that the API is working:

Replace the URL with whatever URL the ApiEndpoint comes out as on the console once dev mode has been started:

    curl -X POST https://de6pgy115l.execute-api.eu-west-2.amazonaws.com  -H 'Content-Type: application/json' -d '{"prompt":"What is so great about AI in less then 100 words."}'


# Deploying to Production

    npx sst deploy --profile thesett-prod

### To build it without deploying it

    npx sst build
