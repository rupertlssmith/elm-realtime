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
        channelApiUrl: channelApiUrl
    },
});

const momentoPorts = new MomentoPorts(app);
const dynamoPorts = new DynamoPorts(app);

export async function main(event, context) {
    console.log(Resource.ChannelTable.name);

    const handler = elmServerless.httpApi({
        app: app,
        logger: silent,
        requestPort: 'requestPort',
        responsePort: 'responsePort',
    });

    return await handler(event, context);
}

const silent = {
    info: (_) => {
    }
}
