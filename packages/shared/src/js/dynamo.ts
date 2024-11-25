import { DynamoDB } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";
import * as ports from "./ports" ;

const client = new DynamoDB({});
const documentClient = DynamoDBDocument.from(client);

export class DynamoPorts {
    //app: { ports: Ports };
    app: { ports: any };

    constructor(app: any) {
        console.info("DynamoPorts.constructor");
        this.app = app;

        ports.checkPortsExist(app, [
            "dynamoGet",
            "dynamoPut",
            "dynamoDelete",
            "dynamoBatchGet",
            "dynamoBatchWrite",
            "dynamoQuery",
            "dynamoResponse"
        ]);

        app.ports.dynamoGet.subscribe(this.dynamoGet);
        app.ports.dynamoPut.subscribe(this.dynamoPut);
        app.ports.dynamoDelete.subscribe(this.dynamoDelete);
        app.ports.dynamoBatchGet.subscribe(this.dynamoBatchGet);
        app.ports.dynamoBatchWrite.subscribe(this.dynamoBatchWrite);
        app.ports.dynamoQuery.subscribe(this.dynamoQuery);
    }

    dynamoGet = ([correlationId, params]) => {
        documentClient.get(params, (error, result) => {
            var getResponse;

            if (error) {
                getResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(params, null, 2)
                };
            } else if (Object.entries(result).length === 0) {
                getResponse = {
                    type_: "ItemNotFound"
                }
            } else {
                getResponse = {
                    type_: "Item",
                    item: result
                }
            }

            this.app.ports.dynamoResponse.send([correlationId, getResponse]);
        });
    }

    dynamoPut = ([correlationId, params]) => {
        console.log("dynamoPut: called");

        documentClient.put(params, (error, result) => {
            var putResponse;

            if (error) {
                putResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(params, null, 2)
                };
            } else {
                putResponse = {
                    type_: "Ok"
                }
            }

            this.app.ports.dynamoResponse.send([correlationId, putResponse]);
        });
    }

    dynamoDelete = ([correlationId, params]) => {
        documentClient.delete(params, (error, result) => {
            var deleteResponse;

            if (error) {
                deleteResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(params, null, 2)
                };
            } else {
                deleteResponse = {
                    type_: "Ok"
                }
            }

            this.app.ports.dynamoResponse.send([correlationId, deleteResponse]);
        });
    }

    dynamoBatchGet = ([correlationId, params]) => {
        documentClient.batchGet(params, (error, result) => {
            var getResponse;

            if (error) {
                getResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(params, null, 2)
                };
            } else if (Object.entries(result).length === 0) {
                getResponse = {
                    type_: "Item",
                    item: []
                }
            } else {
                getResponse = {
                    type_: "Item",
                    item: result
                }
            }

            this.app.ports.dynamoResponse.send([correlationId, getResponse]);
        });
    }

    dynamoBatchWrite = ([correlationId, params]) => {
        documentClient.batchWrite(params, (error, result) => {
            var putResponse;

            if (error) {
                putResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(params, null, 2)
                };
            } else {
                putResponse = {
                    type_: "Ok"
                }
            }

            this.app.ports.dynamoResponse.send([correlationId, putResponse]);
        });
    }

    dynamoQuery = ([correlationId, params]) => {
        documentClient.query(params, (error, result) => {
            var getResponse;

            if (error) {
                getResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(params, null, 2)
                };
            } else if (Object.entries(result).length === 0) {
                getResponse = {
                    type_: "Items",
                    items: []
                }
            } else {
                getResponse = {
                    type_: "Items",
                    items: result.Items
                }
            }

            if (result.LastEvaluatedKey !== undefined) {
                getResponse.lastEvaluatedKey = result.LastEvaluatedKey;
            }

            this.app.ports.dynamoResponse.send([correlationId, getResponse]);
        });
    }
}