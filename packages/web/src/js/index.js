'use strict';

require("./clickoutside.js");
require("./elmresize.js");
require("./elmeditor.js");
const Pointer = require("./pointer.js");
const Navigation = require("./navigation.js");
//const Websockets = require("./websockets.js");
const {MomentoPorts} = require("./momento.ts");
const {Elm} = require('../elm/Top/Top.elm');

const app = Elm.Top.Top.init({
    flags: {
        location: location.href,
        chatApiUrl: process.env.CHAT_API_URL,
        momentoApiKey : process.env.MOMENTO_API_KEY
    },
    node: document.getElementById('application')
});

new Pointer(app);
new Navigation(app);
//new Websockets(app);
new MomentoPorts(app);