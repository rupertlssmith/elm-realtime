'use strict';

require("./clickoutside.js");
require("./elmresize.js");
require("./elmeditor.js");
const Pointer = require("./pointer.js");
const Navigation = require("./navigation.js");
//const Websockets = require("./websockets.js");
const {WebMomentoFactory} = require("../../../shared/src/js/web_momento");
const {MomentoPorts} = require("../../../shared/src/js/momento");
const {Elm} = require('../elm/Top/Top.elm');

const app = Elm.Top.Top.init({
    flags: {
        location: location.href,
        chatApiUrl: process.env.CHAT_API_URL,
        momentoApiKey : process.env.MOMENTO_API_KEY
    },
    node: document.getElementById('application')
});

const pointer = new Pointer(app);
const navigation = new Navigation(app);
const momentoFactory = new WebMomentoFactory();
const momentoPorts = new MomentoPorts(app, momentoFactory);
//new Websockets(app);
