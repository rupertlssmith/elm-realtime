import {
    CacheClient,
    CreateCacheResponse,
    CredentialProvider,
    SubscribeCallOptions,
    TopicClient,
    TopicItem,
    TopicPublishResponse,
    TopicSubscribe,
    TopicSubscribeResponse,
} from "@gomomento/sdk-web";

export class MomentoPorts {
    sockets: { [id: string] : any; } = {};
    app;

    constructor(app: any) {
        console.log("Momento.constructor");
        this.app = app;

        this.onMessage = this.onMessage.bind(this);
        this.open = this.open.bind(this);
        this.send = this.send.bind(this);
        this.close = this.close.bind(this);

        if (app.ports.mmOpen) {
            app.ports.mmOpen.subscribe(this.open);
        }

        if (app.ports.mmSend) {
            app.ports.mmSend.subscribe(this.send);
        }

        if (app.ports.mmClose) {
            app.ports.mmClose.subscribe(this.close);
        }
    }

    async open(args : any) {
        console.log("Momento.open");
        console.log(args);

        // Connect to the Momento Cache.
        const cacheClient = new CacheClient({
            //configuration: Configurations.Laptop.v1(loggerFactory).withClientTimeoutMillis(requestTimeoutMs),
            credentialProvider: CredentialProvider.fromString({apiKey: args.apiKey}),
            defaultTtlSeconds: 60,
        });

        const createCacheResponse = await cacheClient.createCache('TestCache');

        switch (createCacheResponse.type) {
            case CreateCacheResponse.AlreadyExists:
                console.log('cache already exists');
                break;
            case CreateCacheResponse.Success:
                console.log('cache created');
                break;
            case CreateCacheResponse.Error:
                console.log("Momento.open.onError");

                if (this.app.ports.mmOnError) {
                    this.app.ports.mmOnError.send({
                        id: args.id,
                        error: createCacheResponse.innerException()
                    });
                }
        }

        // Set up the topic.
        const topicClient = await new TopicClient({
            credentialProvider: CredentialProvider.fromString({apiKey: args.apiKey}),
        });

        console.log("topClient created");

        const topicSubscribeResponse = await topicClient.subscribe("TestCache", "TestTopic", {
            onError: () => {
                return;
            },
            onItem: (item) => {
                console.log(`Received an item on subscription for 'TestTopic': ${item.value().toString()}`);
                this.onMessage(args.id, JSON.stringify(item));

                return;
            },
        });

        switch (topicSubscribeResponse.type) {
            case TopicSubscribeResponse.Subscription:
                console.log("Successfully subscribed to topic 'test-topic'");
                break;
            case TopicSubscribeResponse.Error:
        }

        // Keep hold of a reference to the topic client and let the application know it is open.
        this.sockets[args.id] = topicClient;

        if (this.app.ports.mmOnOpen) {
            console.log("Momento.open: Sent to port.");
            this.app.ports.mmOnOpen.send(args.id);
        }
    }

    send(args : any) {
        console.log("Momento.send");
        console.log(args);

        const topicClient = this.sockets[args.id];

        if (topicClient) {
            topicClient.publish("TestCache", "TestTopic", args.payload);
        }
    }

    onMessage(id : string, payload : any) {
        console.log("Momento.onMessage");
        console.log(payload);

        if (this.app.ports.mmOnMessage) {
            console.log(payload);
            this.app.ports.mmOnMessage.send({
                id: id,
                payload: payload
            });
        }
    }

    close(id : string) {
        console.log("Momento.close");
        console.log(id);

        const socket = this.sockets[id];

        if (socket) {
            socket.close();
            delete this.sockets[id];
        }
    }
}

