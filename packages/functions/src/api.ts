import {Elm} from './elm.js';
import * as elmServerless from "./bridge/index.js";
import {Resource} from "sst";
import {MomentoPorts} from "../../shared/src/js/momento";
import {DynamoPorts} from "../../shared/src/js/dynamo";

const momentoSecret = JSON.parse(Resource.MomentoApiKey.value);
const channelApiUrl = Resource.ChannelApi.url;

const app = Elm.API.init({
    flags: {
        momentoSecret: momentoSecret,
        channelTable: Resource.ChannelTable.name,
        eventLogTable: Resource.EventLogTable.name,
        channelApiUrl: channelApiUrl
    },
});

const momentoPorts = new MomentoPorts(app);
const dynamoPorts = new DynamoPorts(app);

export async function main(event, context) {
    const handler = elmServerless.httpApi({
        app: app,
        logger: silent,
        requestPort: 'requestPort',
        responsePort: 'responsePort',
    });

    const res = await handler(event, context);
    //console.log(res);
    return res;
}

const silent = {
    info: (_) => {
    }
}
