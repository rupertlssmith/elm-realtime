import {
    CacheClient,
    CacheListPushBackResponse,
    CreateCacheResponse,
    CredentialProvider,
    TopicClient,
    TopicSubscribeResponse,
    TopicPublishResponse, PutWebhookResponse,
} from "@gomomento/sdk";
import * as ports from "./ports" ;

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
    session: Session;
    topic: string;
}

type SendArgs = {
    id: string;
    session: Session;
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
    mmCreateWebhook: { subscribe: any };
    mmOnError: { send: any };
}

export class MomentoPorts {
    app: { ports: Ports };

    constructor(app: any) {
        console.info("Momento.constructor");
        this.app = app;

        ports.checkPortsExist(app, [
            "mmOpen",
            "mmClose",
            "mmSubscribe",
            "mmSend",
            "mmPushList",
            "mmOnOpen",
            "mmOnSubscribe",
            "mmOnMessage",
            "mmOnError",
            "mmCreateWebhook"
        ]);

        app.ports.mmOpen.subscribe(this.open);
        app.ports.mmClose.subscribe(this.close);
        app.ports.mmSubscribe.subscribe(this.subscribe);
        app.ports.mmSend.subscribe(this.send);
        app.ports.mmPushList.subscribe(this.pushList);
        app.ports.mmCreateWebhook.subscribe(this.createWebhook);
    }

    // === Cache session lifecycle.
    open = async (args: OpenArgs) => {
        console.log("Momento.open without bind");
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

                this.app.ports.mmOnError.send({
                    id: args.id,
                    error: createCacheResponse.innerException()
                });
        }

        // Set up the topic client.
        const topicClient = new TopicClient({
            credentialProvider: CredentialProvider.fromString({apiKey: args.apiKey}),
        });

        console.log("topClient created");

        // Provide of a reference to the topic client and let the application know it is open.
        const session = {
            apiKey: args.apiKey,
            cache: args.cache,
            cacheClient: cacheClient,
            topicClient: topicClient
        };

        console.log("Momento.open: Sent to port.");
        this.app.ports.mmOnOpen.send({
            id: args.id,
            session: session
        });
    }

    close = async (args: any) => {
        console.log("Momento.close");
        console.log(args.id);

        args.session.cacheClient.close();
    }

    // === Topics
    subscribe = async (args: SubscribeArgs) => {
        // Set up the topic.
        const topicSubscribeResponse =
            await args.session.topicClient.subscribe(args.session.cache, args.topic, {
                onError: () => {
                    return;
                },
                onItem: (item) => {
                    console.log(`Received an item on subscription for '${args.topic}': ${item.value().toString()}`);
                    this.onMessage(args.id, args.session, JSON.stringify(item));

                    return;
                },
            });

        switch (topicSubscribeResponse.type) {
            case TopicSubscribeResponse.Subscription:
                console.log(`Successfully subscribed to topic '${args.topic}'`);
                break;
            case TopicSubscribeResponse.Error:
        }

        console.log("Momento.mmOnSubscribe: Sent to port.");
        this.app.ports.mmOnSubscribe.send({
            id: args.id,
            session: args.session,
            topic: args.topic
        });
    }

    send = async (args: SendArgs) => {
        console.log("Momento.send");
        console.log(args);

        const publishResponse =
            await args.session.topicClient.publish(args.session.cache, args.topic, args.payload);

        switch (publishResponse.type) {
            case TopicPublishResponse.Success:
                console.log('Value published successfully!');
                break;
            case TopicPublishResponse.Error:
                console.log(`Error publishing value: ${publishResponse.toString()}`);
                break;
        }
    }

    onMessage = (id: string, session: Session, payload: string) => {
        console.log("Momento.onMessage");
        console.log(payload);

        console.log(payload);
        this.app.ports.mmOnMessage.send({
            id: id,
            session: session,
            payload: payload
        });
    }

    // === Lists
    pushList = async (args: any) => {
        console.log("Momento.pushList");

        const pushResponse =
            await args.session.cacheClient.listPushBack(args.session.cache, args.list, args.payload);

        switch (pushResponse.type) {
            case CacheListPushBackResponse.Success:
                console.log(`Value '${args.payload}' added successfully to back of list '${args.list}'`);
                break;
            case CacheListPushBackResponse.Error:
                console.log("Momento.pusList.Error");

                this.app.ports.mmOnError.send({
                    id: args.id,
                    error: pushResponse.innerException()
                });
        }
    }

    // == Webhooks
    createWebhook = async (args: any) => {
        console.log("Momento.createWebhook");
        console.log(args);

        const webhookResponse =
            await args.session.topicClient.putWebhook(
                args.session.cache,
                `${args.topic}-webhook`,
                {
                    topicName: args.topic,
                    destination: args.url
                });

        switch (webhookResponse.type) {
            case PutWebhookResponse.Success:
                console.log('Successfully put webhook');
                break;

            case PutWebhookResponse.Error:
                console.log("Momento.createWebhook.Error");
                console.error(webhookResponse.innerException());

                this.app.ports.mmOnError.send({
                    id: args.id,
                    error: webhookResponse.innerException()
                });
        }
    }
}
