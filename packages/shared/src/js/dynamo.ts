const AWS = require('aws-sdk');
import * as ports from "./ports" ;

let DocumentClient = new AWS.DynamoDB.DocumentClient();


export class DynamoPorts {
    //app: { ports: Ports };
    app: { ports: any };

    constructor(app: any) {
        console.info("Momento.constructor");
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

        app.ports.mmOpen.subscribe(this.open);
    }


    dynamoGet = (responsePort, correlationId, interopId, params) => {
        DocumentClient.get(params, (error, result) => {
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

            responsePort.send([correlationId, interopId, getResponse]);
        });
    }

    let
    dynamoPut = (responsePort, correlationId, interopId, params) => {
        DocumentClient.put(params, (error, result) => {
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

            responsePort.send([correlationId, interopId, putResponse]);
        });
    }

    let
    dynamoDelete = (responsePort, correlationId, interopId, params) => {
        DocumentClient.delete(params, (error, result) => {
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

            responsePort.send([correlationId, interopId, deleteResponse]);
        });
    }

    let
    dynamoBatchGet = (responsePort, correlationId, interopId, params) => {
        DocumentClient.batchGet(params, (error, result) => {
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

            responsePort.send([correlationId, interopId, getResponse]);
        });
    }

    let
    dynamoBatchWrite = (responsePort, correlationId, interopId, params) => {
        DocumentClient.batchWrite(params, (error, result) => {
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

            responsePort.send([correlationId, interopId, putResponse]);
        });
    }

    let
    dynamoQuery = (responsePort, correlationId, interopId, params) => {
        DocumentClient.query(params, (error, result) => {
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

            responsePort.send([correlationId, interopId, getResponse]);
        });
    }
}