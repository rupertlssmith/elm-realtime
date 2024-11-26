import {Elm} from './elm.js';
import * as util from "util";
import * as elmServerless from "./bridge/index.js";
import {Resource} from "sst";
import {MomentoPorts} from "../../shared/src/js/momento";
import {DynamoPorts} from "../../shared/src/js/dynamo";

const momentoSecret = JSON.parse(Resource.MomentoApiKey.value);
const channelApiUrl = Resource.ChannelApi.url;

var app = Elm.API.init({
    flags: {
        momentoSecret: momentoSecret,
        channelApiUrl: channelApiUrl
    },
});

new MomentoPorts(app);
new DynamoPorts(app);

export async function main(event, context) {
    console.log(event);

    const handler = elmServerless.httpApi({
        app: app,
        logger: silent,
        requestPort: 'requestPort',
        responsePort: 'responsePort',
    });
    const asyncHandler = util.promisify(handler);

    const response = await asyncHandler(event, context);
    return response;
}

const silent = {
    info: (_) => {
    }
}
