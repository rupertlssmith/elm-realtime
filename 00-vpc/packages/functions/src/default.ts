import {DynamoDB, ApiGatewayManagementApi} from "aws-sdk";
import {Table} from "sst/node/table";

const TableName = Table.Connections.tableName;
const dynamoDb = new DynamoDB.DocumentClient();

import {APIGatewayProxyHandler} from "aws-lambda";

export const main: APIGatewayProxyHandler = async (event) => {
    const messageData = JSON.parse(event.body).data;
    const {stage, domainName} = event.requestContext;

    // Get all the connections
    const connections = await dynamoDb
        .scan({TableName, ProjectionExpression: "id"})
        .promise();

    const apiG = new ApiGatewayManagementApi({
        endpoint: `${domainName}/${stage}`,
    });

    const postToConnection = async function ({id}) {
        try {
            // Send the message to the given client
            await apiG
                .postToConnection({ConnectionId: id, Data: messageData})
                .promise();
        } catch (e) {
            if (e.statusCode === 410) {
                // Remove stale connections
                await dynamoDb.delete({TableName, Key: {id}}).promise();
            }
        }
    };

    // Iterate through all the connections
    await Promise.all(connections.Items.map(postToConnection));

    return {statusCode: 200, body: "Message sent"};
};

// exports.handler = async function (event) {
//     let connectionInfo;
//     let connectionId = event.requestContext.connectionId;
//
//     const callbackAPI = new ApiGatewayManagementApiClient({
//         apiVersion: '2018-11-29',
//         endpoint: 'https://' + event.requestContext.domainName + '/' + event.requestContext.stage
//     });
//
//     try {
//         connectionInfo = await callbackAPI.send(new GetConnectionCommand(
//             {ConnectionId: event.requestContext.connectionId}
//         ));
//     } catch (e) {
//         console.log(e);
//     }
//
//     connectionInfo.connectionID = connectionId;
//
//     await callbackAPI.send(new PostToConnectionCommand(
//         {
//             ConnectionId: event.requestContext.connectionId,
//             Data:
//                 'Use the sendmessage route to send a message. Your info:' +
//                 JSON.stringify(connectionInfo)
//         }
//     ));
//     return {
//         statusCode: 200,
//     };
// };
