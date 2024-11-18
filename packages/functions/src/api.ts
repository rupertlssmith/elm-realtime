import {Elm} from './elm.js';
import * as util from "util";
import * as elmServerless from "./bridge/index.js";
import {Resource} from "sst";

const momentoSecret = JSON.parse(Resource.MomentoApiKey.value);

const app = Elm.API.init({
    flags: {
        momentoSecret: momentoSecret
    },
});

export async function main(event, context) {
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
