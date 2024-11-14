import {Resource} from "sst";
import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import {DynamoDB} from "@aws-sdk/client-dynamodb";
import {
    ApiGatewayManagementApiClient,
    PostToConnectionCommand,
} from "@aws-sdk/client-apigatewaymanagementapi";
import {
    TopicClient,
    TopicConfigurations,
    TopicPublishResponse,
    CredentialProvider
} from '@gomomento/sdk';
import {ensureCacheExists} from './utils/cache'

const TableName = Resource.Connections.name;
const dynamoDb = DynamoDBDocument.from(new DynamoDB());

export async function main(event) {
    console.log("sendmessage invoked");
    const messageData = JSON.parse(event.body).data;
    //const {stage, domainName} = event.requestContext;

    const momentoSecret = JSON.parse(Resource.MomentoApiKey.value);
    console.log(momentoSecret.apiKey);

    const topicClient = new TopicClient({
        configuration: TopicConfigurations.Default.latest(),
        credentialProvider: CredentialProvider.fromString({apiKey: momentoSecret.apiKey}),
    });

    const topicName = "TestTopic";
    const cacheName = "TestCache";
    //const value = {"message": "Momento Hello World"};
    const value = "Momento Hello World";

    await ensureCacheExists(momentoSecret.apiKey, cacheName);

    console.log(`Publishing cacheName=${cacheName}, topicName=${topicName}, value=${value}`);
    const publishResponse = await topicClient.publish(cacheName, topicName, value);
    switch (publishResponse.type) {
        case TopicPublishResponse.Success:
            console.log('Value published successfully!');
            break;
        case TopicPublishResponse.Error:
            console.log(`Error publishing value: ${publishResponse.toString()}`);
            break;
    }

    return {statusCode: 200, body: "Message sent"};
};