const xmlhttprequest = require('./xmlhttprequest');

const defaultLogger = require('./logger');
const requestHandler = require('./request-handler');
const responseHandler = require('./response-handler');
import * as ports from "../../../shared/src/js/ports.js"

global.XMLHttpRequest = xmlhttprequest.XMLHttpRequest;

const httpApi = ({
                     app,
                     logger = defaultLogger,
                     requestPort = 'requestPort',
                     responsePort = 'responsePort',
                 } = {}) => {
    ports.checkPortsExist(app, [requestPort, responsePort]);

    const handleResponse = responseHandler({logger});

    app.ports[responsePort].subscribe(([id, callback, jsonValue]) => {
        handleResponse(id, callback, jsonValue);
    });

    return requestHandler({
        requestPort: app.ports[requestPort],
        logger: logger
    });
};

module.exports = {httpApi};
