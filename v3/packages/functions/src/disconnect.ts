import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import {DynamoDB} from "@aws-sdk/client-dynamodb";
import { Resource } from "sst";

const dynamoDb = DynamoDBDocument.from(new DynamoDB());

export async function main(event) {
    const params = {
        TableName: Resource.Connections.name,
        Key: {
            id: event.requestContext.connectionId,
        },
    };

    await dynamoDb.delete(params);

    return {statusCode: 200, body: "Disconnected"};
};