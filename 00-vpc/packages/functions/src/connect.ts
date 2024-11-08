import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import {DynamoDB} from "@aws-sdk/client-dynamodb";
import {Table} from "sst/node/table";

const dynamoDb = DynamoDBDocument.from(new DynamoDB());

import {APIGatewayProxyHandler} from "aws-lambda";

export const main: APIGatewayProxyHandler = async (event) => {
    const params = {
        TableName: Table.Connections.tableName,
        Item: {
            id: event.requestContext.connectionId,
        },
    };

    await dynamoDb.put(params);

    return {statusCode: 200, body: "Connected"};
};
