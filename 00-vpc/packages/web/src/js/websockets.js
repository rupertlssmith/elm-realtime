//var mySockets = {};

class Websockets {
    sockets = {};
    app;

    constructor(app) {
        console.log("Websocket.constructor");
        this.app = app;

        this.onMessage = this.onMessage.bind(this);
        this.open = this.open.bind(this);
        this.send = this.send.bind(this);
        this.close = this.close.bind(this);

        if (app.ports.wsOpen) {
            app.ports.wsOpen.subscribe(this.open);
        }

        if (app.ports.wsSend) {
            app.ports.wsSend.subscribe(this.send);
        }

        if (app.ports.wsClose) {
            app.ports.wsClose.subscribe(this.close);
        }
    }

    open(args) {
        console.log("Websocket.open");
        console.log(args);

        let socket = new WebSocket(args.url);
        socket.onmessage = this.onMessage(args.id);
        this.sockets[args.id] = socket;

        socket.onopen = function () {
            console.log("Websocket.onOpen");

            if (this.app.ports.wsOnOpen) {
                console.log("Websocket.open: Sent to port.");
                this.app.ports.wsOnOpen.send(args.id);
            }
        }.bind(this);
    }

    send(args) {
        console.log("Websocket.send");
        console.log(args);

        const socket = this.sockets[args.id];

        if (socket) {
            socket.send(args.payload);
        }
    }

    onMessage(id) {
        const handler = function (evt) {
            console.log("Websocket.onMessage");
            console.log(evt);

            if (this.app.ports.wsOnMessage) {
                this.app.ports.wsOnMessage.send({
                    id: id,
                    payload: evt.data
                });
            }

        }.bind(this);;

        return handler;
    }

    close(id) {
        console.log("Websocket.close");
        console.log(id);

        const socket = this.sockets[id];

        if (socket) {
            socket.close();
            delete sockets[id];
        }
    }
}

module.exports = Websockets;