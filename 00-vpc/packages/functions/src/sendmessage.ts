import {ApiGatewayManagementApi} from "@aws-sdk/client-apigatewaymanagementapi";
import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import {DynamoDB} from "@aws-sdk/client-dynamodb";
import {Table} from "sst/node/table";

const TableName = Table.Connections.tableName;
const dynamoDb = DynamoDBDocument.from(new DynamoDB());

import {APIGatewayProxyHandler} from "aws-lambda";

export const main: APIGatewayProxyHandler = async (event) => {
    console.log("sendmessage invoked");
    const messageData = JSON.parse(event.body).data;
    const {stage, domainName} = event.requestContext;

    // Get all the connections
    const connections = await dynamoDb
        .scan({TableName, ProjectionExpression: "id"});

    const apiG = new ApiGatewayManagementApi({
        endpoint: `https://${domainName}/${stage}`,
    });

    const postToConnection = async function ({id}) {
        try {
            // Send the message to the given client
            await apiG.postToConnection({ConnectionId: id, Data: messageData});
        } catch (e) {
            if (e.statusCode === 410) {
                // Remove stale connections
                await dynamoDb.delete({TableName, Key: {id}});
            }
        }
    };

    // Iterate through all the connections
    await Promise.all(connections.Items.map(postToConnection));

    return {statusCode: 200, body: "Message sent"};
};