import {DynamoDB} from "@aws-sdk/client-dynamodb";
import {DynamoDBDocument} from "@aws-sdk/lib-dynamodb";
import * as ports from "./ports" ;
import {GetCommandInput} from "@aws-sdk/lib-dynamodb/dist-types/commands/GetCommand";
import {PutCommandInput} from "@aws-sdk/lib-dynamodb/dist-types/commands/PutCommand";
import {DeleteCommandInput} from "@aws-sdk/lib-dynamodb/dist-types/commands/DeleteCommand";
import {BatchGetCommandInput} from "@aws-sdk/lib-dynamodb/dist-types/commands/BatchGetCommand";
import {BatchWriteCommandInput} from "@aws-sdk/lib-dynamodb/dist-types/commands/BatchWriteCommand";
import {QueryCommandInput} from "@aws-sdk/lib-dynamodb/dist-types/commands/QueryCommand";

const client = new DynamoDB();
const documentClient = DynamoDBDocument.from(client);

type GetArgs = {
    id: String;
    req: GetCommandInput;
}

type PutArgs = {
    id: String;
    req: PutCommandInput;
}

type DeleteArgs = {
    id: String;
    req: DeleteCommandInput;
}

type BatchGetArgs = {
    id: String;
    req: BatchGetCommandInput;
}

type BatchWriteArgs = {
    id: String;
    req: BatchWriteCommandInput;
}

type QueryArgs = {
    id: String;
    req: QueryCommandInput;
}

type Ports = {
    dynamoGet: { subscribe: any };
    dynamoPut: { subscribe: any };
    dynamoDelete: { subscribe: any };
    dynamoBatchGet: { subscribe: any };
    dynamoBatchWrite: { subscribe: any };
    dynamoQuery: { subscribe: any };
    dynamoResponse: { send: any };
}

export class DynamoPorts {
    app: { ports: Ports };

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

    dynamoGet = async (args: GetArgs) => {
        documentClient.get(args.req, (error, result) => {
            var getResponse;

            if (error) {
                getResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(args.req, null, 2)
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

            this.app.ports.dynamoResponse.send({id: args.id, res: getResponse});
        });
    }

    dynamoPut = async (args: PutArgs) => {
        //console.log("dynamoPut: called");

        documentClient.put(args.req, (error, result) => {
            var putResponse;

            if (error) {
                putResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(args.req, null, 2)
                };
            } else {
                putResponse = {
                    type_: "Ok"
                }
            }

            this.app.ports.dynamoResponse.send({id: args.id, res: putResponse});
        });
    }

    dynamoDelete = async (args: DeleteArgs) => {
        documentClient.delete(args.req, (error, result) => {
            var deleteResponse;

            if (error) {
                deleteResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(args.req, null, 2)
                };
            } else {
                deleteResponse = {
                    type_: "Ok"
                }
            }

            this.app.ports.dynamoResponse.send({id: args.id, res: deleteResponse});
        });
    }

    dynamoBatchGet = async (args: BatchGetArgs) => {
        documentClient.batchGet(args.req, (error, result) => {
            var getResponse;

            if (error) {
                getResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(args.req, null, 2)
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

            this.app.ports.dynamoResponse.send({id: args.id, res: getResponse});
        });
    }

    dynamoBatchWrite = async (args: BatchWriteArgs) => {
        documentClient.batchWrite(args.req, (error, result) => {
            var putResponse;

            if (error) {
                putResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(args.req, null, 2)
                };
            } else {
                putResponse = {
                    type_: "Ok"
                }
            }

            this.app.ports.dynamoResponse.send({id: args.id, res: putResponse});
        });
    }

    dynamoQuery = async (args: QueryArgs) => {
        documentClient.query(args.req, (error, result) => {
            var getResponse;

            if (error) {
                getResponse = {
                    type_: "Error",
                    errorMsg: JSON.stringify(error, null, 2) + "\n" + JSON.stringify(args.req, null, 2)
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

            this.app.ports.dynamoResponse.send({id: args.id, res: getResponse});
        });
    }
}