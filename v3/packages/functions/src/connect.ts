import {Resource} from "sst";
import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import {DynamoDB} from "@aws-sdk/client-dynamodb";

const dynamoDb = DynamoDBDocument.from(new DynamoDB());

export async function main(event) {
    console.log("connect called");

    const params = {
        TableName: Resource.Connections.name,
        Item: {
            id: event.requestContext.connectionId,
        },
    };

    await dynamoDb.put(params);

    return {statusCode: 200, body: "Connected"};
}