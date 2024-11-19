import {Elm} from './elm.js';
import * as util from "util";
import * as elmServerless from "./bridge/index.js";
import {Resource} from "sst";
import {MomentoPorts} from "./momento";

const momentoSecret = JSON.parse(Resource.MomentoApiKey.value);
const channelApiUrl = Resource.ChannelApi.url;

const app = Elm.API.init({
    flags: {
        momentoSecret: momentoSecret,
        channelApiUrl: channelApiUrl
    },
});

new MomentoPorts(app);

export async function main(event, context) {
    //console.log(event);

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
    info : (_) => {}
}
