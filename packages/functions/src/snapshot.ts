import {Elm} from './elm.js';
import {Resource} from "sst";
import {DynamoPorts} from "../../shared/src/js/dynamo";
import * as ports from "../../shared/src/js/ports";
import util from "util";

//======= SQS Stuff

type Ports = {
    sqsLambdaSubscribe: { send: any };
    responsePort: { subscribe: any };
}

const missingStatusCodeBody = 'Application did not return a valid status code';

const defaultHeaders = (body) => (typeof body === 'object'
    ? {'content-type': 'application/json; charset=utf-8'}
    : {'content-type': 'text/text; charset=utf-8'});

const encodeBody = (body) => {
    switch (typeof body) {
        case 'string':
        case 'undefined':
            return body;
        case 'object':
            return JSON.stringify(body);
        default:
            return `${body}`;
    }
};

const defaultLogger = console;

class SqsLambdaPorts {
    app: { ports: Ports };
    logger;

    constructor(app: any, logger = defaultLogger) {
        //console.info("SqsLambdaPorts.constructor");
        this.app = app;
        this.logger = logger;

        ports.checkPortsExist(app, [
            "sqsLambdaSubscribe",
            "responsePort"
        ]);
    }

    handler = () => {
        this.logger.info("handler: called");

        app.ports.responsePort.subscribe(({session, res}) => {
            this.responsePort(session, res);
        });

        return util.promisify(this.handlerWithCallback);
    }

    handlerWithCallback = (event, callback) => {
        this.logger.info("handlerWithCallback: called");
        app.ports.sqsLambdaSubscribe.send({session: callback, req: event});
    }

    responsePort = (callback: any, resp: any) => {
        this.logger.info("responsePort: called");
        this.logger.info(JSON.stringify({resp}, null, 2));
        const statusCode = parseInt(resp.statusCode, 10);

        if (isNaN(statusCode)) {
            callback(null, {
                statusCode: 500,
                body: `${missingStatusCodeBody}: ${resp.statusCode}`,
                headers: defaultHeaders(''),
                isBase64Encoded: !!resp.isBase64Encoded
            });
        } else {
            callback(null, {
                statusCode,
                body: encodeBody(resp.body),
                headers: resp.headers || defaultHeaders(resp.body),
                isBase64Encoded: !!resp.isBase64Encoded
            });
        }
    }
}

//==================

const momentoSecret = JSON.parse(Resource.MomentoApiKey.value);
const channelApiUrl = Resource.ChannelApi.url;

const app = Elm.API.init({
    flags: {
        awsRegion: process.env.AWS_REGION,
        awsAccessKeyId: process.env.AWS_ACCESS_KEY_ID,
        awsSecretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        awsSessionToken: process.env.AWS_SESSION_TOKEN,
        momentoSecret: momentoSecret,
        channelTable: Resource.ChannelTable.name,
        eventLogTable: Resource.EventLogTable.name,
        channelApiUrl: channelApiUrl,
        snapshotQueueUrl: Resource.SnapshotQueue.url
    },
});

const silent = {
    info: (_) => {
    }
}

const dynamoPorts = new DynamoPorts(app);
const sqsLambdaPorts = new SqsLambdaPorts(app, silent);

export async function main(event, context) {
    // console.log(context);
    // console.log(event);

    const res = await sqsLambdaPorts.handler()(event);

    //console.log(res);
    return res;
}


