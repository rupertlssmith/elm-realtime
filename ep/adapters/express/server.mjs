import express from "express";
import session from "express-session";
import cors from "cors";
import http from "http";
import "uuid";
import { WebSocketServer } from "ws";

import elmPagesMiddleware from "./middleware.mjs";

const app = express();
const port = 7000;

// Set up CORS
var corsOptions = {
    origin: '*',
    credentials: true
};
app.use(cors(corsOptions));

app.use(express.static("dist"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(elmPagesMiddleware);
// app.listen(port, () => {
//   console.log(`Listening on port ${port}`);
// });

// Holds websockets by user id.
const map = new Map();

// Express session parser - the same for the HTTP and WS endpoints.
const sessionParser = session({
    saveUninitialized: false,
    secret: '$eCuRiTy',
    resave: false,
});
app.use(sessionParser);

// Generate a user id on login and store it in the session.
app.post('/login', function (req, res) {
    const id = uuid.v4();

    console.log(`Updating session for user ${id}`);
    req.session.userId = id;
    res.send({result: 'OK', message: 'Session updated'});
});

// Delete the user id on logout from the session, and also close any websocket associated with it.
app.delete('/logout', function (request, response) {
    const ws = map.get(request.session.userId);

    console.log('Destroying session');
    request.session.destroy(function () {
        if (ws) ws.close();

        response.send({result: 'OK', message: 'Session destroyed'});
    });
});

// Provide the auth endpoints over HTTP.
const server = http.createServer(app);

server.listen(port, function () {
    console.log(`Listening on https://localhost:${port}`);
});

server.on('upgrade', function (request, socket, head) {
    socket.on('error', onSocketError);

    console.log('Parsing session from request...');

    sessionParser(request, {}, () => {
        if (!request.session.userId) {
            socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
            socket.destroy();
            return;
        }

        console.log('Session is parsed!');

        socket.removeListener('error', onSocketError);

        wss.handleUpgrade(request, socket, head, function (ws) {
            wss.emit('connection', ws, request);
        });
    });
});

function onSocketError(err) {
    console.error(err);
}

// Provide the websocket endpoint.
const wss = new WebSocketServer({clientTracking: false, noServer: true});

// Listen for connections.
wss.on('connection', function (ws, request) {
    const userId = request.session.userId;

    map.set(userId, ws);

    ws.on('error', console.error);

    ws.on('message', function (message) {
        // Here we can now use session parameters.
        console.log(`Received message ${message} from user ${userId}`);
        ws.send(`${message}`);
    });

    ws.on('close', function () {
        map.delete(userId);
    });
});

