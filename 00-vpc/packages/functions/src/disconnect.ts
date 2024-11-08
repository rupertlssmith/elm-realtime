import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import {DynamoDB} from "@aws-sdk/client-dynamodb";
import {Table} from "sst/node/table";

const dynamoDb = DynamoDBDocument.from(new DynamoDB());

import {APIGatewayProxyHandler} from "aws-lambda";

export const main: APIGatewayProxyHandler = async (event) => {
    const params = {
        TableName: Table.Connections.tableName,
        Key: {
            id: event.requestContext.connectionId,
        },
    };

    await dynamoDb.delete(params);

    return {statusCode: 200, body: "Disconnected"};
};