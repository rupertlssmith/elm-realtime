import {Elm} from './elm.js';
import * as elmServerless from "../../shared/src/js/httpserver/index.js";
import {Resource} from "sst";
import {NodeMomentoFactory} from "../../shared/src/js/node_momento";
import {MomentoPorts} from "../../shared/src/js/momento";
import {DynamoPorts} from "../../shared/src/js/dynamo";

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
        snapshotTable : Resource.SnapshotTable.name,
        channelApiUrl: channelApiUrl,
        snapshotQueueUrl : Resource.SnapshotQueue.url
    },
});

const momentoFactory = new NodeMomentoFactory();
const momentoPorts = new MomentoPorts(app, momentoFactory);
const dynamoPorts = new DynamoPorts(app);

export async function main(event, context) {
    const handler = elmServerless.httpApi({
        app: app,
        logger: silent,
        requestPort: 'requestPort',
        responsePort: 'responsePort',
    });


    // console.log(context);
    // console.log(event);
    const res = await handler(event, context);
    // console.log(res);
    return res;
}

const silent = {
    info: (_) => {
    }
}
