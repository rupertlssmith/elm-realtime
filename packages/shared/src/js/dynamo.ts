const AWS = require('aws-sdk');
import * as ports from "./ports" ;

let documentClient = new AWS.DynamoDB.DocumentClient();

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

        app.ports.dynamoGet.subscribe(this.dynamoGet);
        app.ports.dynamoPut.subscribe(this.dynamoPut);
        app.ports.dynamoDelete.subscribe(this.dynamoDelete);
        app.ports.dynamoBatchGet.subscribe(this.dynamoBatchGet);
        app.ports.dynamoBatchWrite.subscribe(this.dynamoBatchWrite);
        app.ports.dynamoQuery.subscribe(this.dynamoQuery);
    }

    dynamoGet = (correlationId, params) => {
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

    dynamoPut = (responsePort, correlationId, params) => {
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

    dynamoDelete = (responsePort, correlationId, params) => {
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

    dynamoBatchGet = (responsePort, correlationId, params) => {
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

    dynamoBatchWrite = (responsePort, correlationId, params) => {
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

    dynamoQuery = (responsePort, correlationId, params) => {
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