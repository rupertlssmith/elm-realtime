import {
    CacheClient,
    CacheListPushBackResponse,
    CreateCacheResponse,
    CredentialProvider,
    TopicClient,
    TopicSubscribeResponse,
} from "@gomomento/sdk-web";

type Session = {
    apiKey: string;
    cache: string;
    cacheClient: CacheClient;
    topicClient: TopicClient
}

type OpenArgs = {
    id: string;
    apiKey: string;
    cache: string;
    topic: string
}

type SubscribeArgs = {
    id: string;
    topic: string;
}

type SendArgs = {
    id: string;
    topic: string;
    payload: string
}

type Ports = {
    mmOpen: { subscribe: any };
    mmOnOpen: { send: any };
    mmClose: { subscribe: any };
    mmSubscribe: { subscribe: any };
    mmOnSubscribe: { send: any };
    mmSend: { subscribe: any };
    mmOnMessage: { send: any };
    mmPushList: { subscribe: any };
    mmOnError: { send: any };
}

export class MomentoPorts {
    sessions: { [id: string]: Session; } = {};
    app: { ports: Ports };

    constructor(app: any) {
        console.log("Momento.constructor");
        this.app = app;

        this.onMessage = this.onMessage.bind(this);
        this.open = this.open.bind(this);
        this.subscribe = this.subscribe.bind(this);
        this.send = this.send.bind(this);
        this.close = this.close.bind(this);
        this.pushList = this.pushList.bind(this);

        if (app.ports.mmOpen) {
            app.ports.mmOpen.subscribe(this.open);
        }

        if (app.ports.mmClose) {
            app.ports.mmClose.subscribe(this.close);
        }

        if (app.ports.mmSubscribe) {
            app.ports.mmSubscribe.subscribe(this.subscribe);
        }

        if (app.ports.mmSend) {
            app.ports.mmSend.subscribe(this.send);
        }

        if (app.ports.mmPushList) {
            app.ports.mmPushList.subscribe(this.pushList);
        }
    }

    // === Cache session lifecycle.
    async open(args: OpenArgs) {
        console.log("Momento.open");
        console.log(args);

        // Connect to the Momento Cache.
        const cacheClient = new CacheClient({
            //configuration: Configurations.Laptop.v1(loggerFactory).withClientTimeoutMillis(requestTimeoutMs),
            credentialProvider: CredentialProvider.fromString({apiKey: args.apiKey}),
            defaultTtlSeconds: 60,
        });

        const createCacheResponse = await cacheClient.createCache(args.cache);

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

        // Set up the topic client.
        const topicClient = new TopicClient({
            credentialProvider: CredentialProvider.fromString({apiKey: args.apiKey}),
        });

        console.log("topClient created");

        // Keep hold of a reference to the topic client and let the application know it is open.
        this.sessions[args.id] = {
            apiKey: args.apiKey,
            cache: args.cache,
            cacheClient: cacheClient,
            topicClient: topicClient
        };

        if (this.app.ports.mmOnOpen) {
            console.log("Momento.open: Sent to port.");
            this.app.ports.mmOnOpen.send(args.id);
        }
    }

    close(id: string) {
        console.log("Momento.close");
        console.log(id);

        const session = this.sessions[id];

        if (session) {
            session.cacheClient.close();
            delete this.sessions[id];
        }
    }

    // === Topics
    async subscribe(args: SubscribeArgs) {
        const session = this.sessions[args.id];

        if (session) {
            // Set up the topic.
            const topicSubscribeResponse = await session.topicClient.subscribe(session.cache, args.topic, {
                onError: () => {
                    return;
                },
                onItem: (item) => {
                    console.log(`Received an item on subscription for '${args.topic}': ${item.value().toString()}`);
                    this.onMessage(args.id, JSON.stringify(item));

                    return;
                },
            });

            switch (topicSubscribeResponse.type) {
                case TopicSubscribeResponse.Subscription:
                    console.log(`Successfully subscribed to topic '${args.topic}'`);
                    break;
                case TopicSubscribeResponse.Error:
            }

            if (this.app.ports.mmOnSubscribe) {
                console.log("Momento.mmOnSubscribe: Sent to port.");
                this.app.ports.mmOnSubscribe.send({
                    id: args.id,
                    topic: args.topic
                });
            }
        }
    }

    async send(args: SendArgs) {
        console.log("Momento.send");
        console.log(args);

        const session = this.sessions[args.id];

        if (session) {
            const publishResponse = await session.topicClient.publish(session.cache, args.topic, args.payload);
        }
    }

    onMessage(id: string, payload: string) {
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

    // === Lists
    async pushList(args: any) {
        const session = this.sessions[args.id];

        if (session) {
            const pushResponse = await session.cacheClient.listPushBack(session.cache, args.list, args.payload);

            switch (pushResponse.type) {
                case CacheListPushBackResponse.Success:
                    console.log(`Value '${args.payload}' added successfully to back of list '${args.list}'`);
                    break;
                case CacheListPushBackResponse.Error:
                    console.log("Momento.pusList.Error");

                    if (this.app.ports.mmOnError) {
                        this.app.ports.mmOnError.send({
                            id: args.id,
                            error: pushResponse.innerException()
                        });
                    }
            }
        }
    }
}
