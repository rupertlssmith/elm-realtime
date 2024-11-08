import {Resource} from "sst";
import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import {DynamoDB} from "@aws-sdk/client-dynamodb";
import {
    ApiGatewayManagementApiClient,
    PostToConnectionCommand,
} from "@aws-sdk/client-apigatewaymanagementapi";

const TableName = Resource.Connections.name;
const dynamoDb = DynamoDBDocument.from(new DynamoDB());

export async function main(event) {
    console.log("sendmessage invoked");
    const messageData = JSON.parse(event.body).data;
    //const {stage, domainName} = event.requestContext;

    // Get all the connections
    const connections = await dynamoDb
        .scan({TableName, ProjectionExpression: "id"});

    const apiG = new ApiGatewayManagementApiClient({
        endpoint: Resource.api.managementEndpoint,
    });

    const postToConnection = async function ({id}) {
        try {
            // Send the message to the given client
            await apiG.send(
                new PostToConnectionCommand({
                    ConnectionId: event.requestContext.connectionId,
                    Data: messageData,
                }));
        } catch (e) {
            console.log(e);

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