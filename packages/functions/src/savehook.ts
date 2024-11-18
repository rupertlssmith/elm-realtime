import {Resource} from "sst";
import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import {DynamoDB} from "@aws-sdk/client-dynamodb";
import {
    TopicClient,
    TopicConfigurations,
    TopicPublishResponse,
    CredentialProvider,
    CacheClient, CacheListFetchResponse, CacheListRemoveValueResponse
} from '@gomomento/sdk';

const TableName = Resource.Connections.name;
const dynamoDb = DynamoDBDocument.from(new DynamoDB());

const topicName = "TestTopic";
const cacheName = "TestCache";
const value = "Momento Hello World";

export async function main(event) {
    console.log("savehook invoked");
    const messageData = JSON.parse(event.body).data;

    const momentoSecret = JSON.parse(Resource.MomentoApiKey.value);
    console.log(momentoSecret.apiKey);

    // Obtain a connection to the cache.
    const cacheClient = new CacheClient({
        credentialProvider: CredentialProvider.fromString({apiKey: momentoSecret.apiKey}),
        defaultTtlSeconds: 60,
    });

    const topicClient = new TopicClient({
        configuration: TopicConfigurations.Default.latest(),
        credentialProvider: CredentialProvider.fromString({apiKey: momentoSecret.apiKey}),
    });

    // Read the saved events from the cache list.
    const fetchResult = await cacheClient.listFetch(cacheName, 'test-list');

    console.log(`cache hit: ${fetchResult.value()!}`);

    switch (fetchResult.type) {
        case CacheListFetchResponse.Hit:
            console.log(`List fetched successfully: ${fetchResult.value()}`);
            break;
        case CacheListFetchResponse.Miss:
            console.log(`List 'savelist' was not found in cache '${cacheName}'`);
            return {statusCode: 200, body: "Save list not found in cache."};
        case CacheListFetchResponse.Error:
            throw new Error(
                `An error occurred while attempting to fetch the list 'test-list' from cache '${cacheName}': ${fetchResult.errorCode()}: ${fetchResult.toString()}`
            );
    }

    // Save the events to the dynamodb event log.

    // Remove the saved events from the cache list.
    const removeResult = await cacheClient.listRemoveValue(cacheName, 'test-list', 'b');

    switch (removeResult.type) {
        case CacheListRemoveValueResponse.Success:
            console.log("Value 'b' removed successfully from list 'test-list'");
            break;
        case CacheListRemoveValueResponse.Error:
            throw new Error(
                `An error occurred while attempting to call cacheListRemoveValue on list 'test-list' in cache '${cacheName}': ${removeResult.errorCode()}: ${removeResult.toString()}`
            );
    }

    // Publish the saved event to the model topic.
    const publishResponse = await topicClient.publish(cacheName, "modeltopic", "payload");

    switch (publishResponse.type) {
        case TopicPublishResponse.Success:
            console.log('Value published successfully!');
            break;
        case TopicPublishResponse.Error:
            console.log(`Error publishing value: ${publishResponse.toString()}`);
            break;
    }

    // Everything completed succesfully.
    return {statusCode: 200, body: "Message sent"};
}
