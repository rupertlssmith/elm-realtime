import {
    CacheClient,
    CacheListPushBackResponse,
    CreateCacheResponse,
    CredentialProvider,
    TopicClient,
    TopicSubscribeResponse,
    TopicPublishResponse, PutWebhookResponse, CacheListPopFrontResponse,
} from "@gomomento/sdk-web";
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
    payload: any
}

type PushListArgs = {
    id: string;
    session: Session;
    list: string;
    payload: any;
}

type PopListArgs = {
    id: string;
    session: Session;
    list: string;
}

type CreateWebhookArgs = {
    id: string;
    session: Session;
    name: string;
    topic: string;
    url: string;
}

type Ports = {
    mmOpen: { subscribe: any };
    mmClose: { subscribe: any };
    mmSubscribe: { subscribe: any };
    mmPublish: { subscribe: any };
    mmOnMessage: { send: any };
    mmPushList: { subscribe: any };
    mmPopList: { subscribe: any };
    mmCreateWebhook: { subscribe: any };
    mmResponse: { send: any };
    mmAsyncError: { send: any };
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
            "mmPublish",
            "mmOnMessage",
            "mmPushList",
            "mmPopList",
            "mmCreateWebhook",
            "mmResponse",
            "mmAsyncError"
        ]);

        app.ports.mmOpen.subscribe(this.open);
        app.ports.mmClose.subscribe(this.close);
        app.ports.mmSubscribe.subscribe(this.subscribe);
        app.ports.mmPublish.subscribe(this.publish);
        app.ports.mmPushList.subscribe(this.pushList);
        app.ports.mmPopList.subscribe(this.popList);
        app.ports.mmCreateWebhook.subscribe(this.createWebhook);
    }

    // === Cache session lifecycle.
    open = async (args: OpenArgs) => {
        // console.log("Momento.open");
        // console.log(args);

        // Connect to the Momento Cache.
        const cacheClient = new CacheClient({
            //configuration: Configurations.Laptop.v1(loggerFactory).withClientTimeoutMillis(requestTimeoutMs),
            credentialProvider: CredentialProvider.fromString({apiKey: args.apiKey}),
            defaultTtlSeconds: 60,
        });

        const createCacheResponse = await cacheClient.createCache(args.cache);

        switch (createCacheResponse.type) {
            case CreateCacheResponse.AlreadyExists:
                //console.log('cache already exists');
                break;
            case CreateCacheResponse.Success:
                //console.log('cache created');
                break;
            case CreateCacheResponse.Error:
                //console.log("Momento.open.onError");

                this.app.ports.mmResponse.send({
                    id: args.id,
                    type_: "Error",
                    response: createCacheResponse.innerException()
                });
        }

        // Set up the topic client.
        const topicClient = new TopicClient({
            credentialProvider: CredentialProvider.fromString({apiKey: args.apiKey}),
        });

        // Provide of a reference to the topic client and let the application know it is open.
        const session = {
            apiKey: args.apiKey,
            cache: args.cache,
            cacheClient: cacheClient,
            topicClient: topicClient
        };

        this.app.ports.mmResponse.send({
            id: args.id,
            type_: "Ok",
            response: session
        });
    }

    close = async (args: any) => {
        // console.log("Momento.close");
        // console.log(args.id);

        args.session.cacheClient.close();

        this.app.ports.mmResponse.send({
            id: args.id,
            type_: "Ok",
            response: args.session
        });
    }

    // === Topics
    subscribe = async (args: SubscribeArgs) => {
        // Set up the topic.
        const topicSubscribeResponse =
            await args.session.topicClient.subscribe(args.session.cache, args.topic, {
                onError: (err) => {
                    this.app.ports.mmAsyncError.send({
                        id: args.id,
                        response: err.toString()
                    });

                    return;
                },
                onItem: (item) => {
                    //console.log(`Received an item on subscription for '${args.topic}': ${item.value().toString()}`);
                    //this.onMessage(args.id, args.session, JSON.stringify(item));
                    this.onMessage(args.id, args.session, JSON.parse(item.value().toString()));

                    return;
                },
            });

        switch (topicSubscribeResponse.type) {
            case TopicSubscribeResponse.Subscription:
                //console.log(`Successfully subscribed to topic '${args.topic}'`);
                break;

            case TopicSubscribeResponse.Error:
                this.app.ports.mmResponse.send({
                    id: args.id,
                    type_: "Error",
                    response: topicSubscribeResponse.innerException()
                });
        }

        this.app.ports.mmResponse.send({
            id: args.id,
            type_: "Ok",
            response: args.session
        });
    }

    publish = async (args: SendArgs) => {
        // console.log("Momento.send");
        // console.log(args);

        const publishResponse =
            await args.session.topicClient.publish(
                args.session.cache,
                args.topic,
                JSON.stringify(args.payload));

        switch (publishResponse.type) {
            case TopicPublishResponse.Success:
                //console.log('Value published successfully!');
                break;
            case TopicPublishResponse.Error:
                //console.log(`Error publishing value: ${publishResponse.toString()}`);

                this.app.ports.mmAsyncError.send({
                    id: args.id,
                    response: publishResponse.innerException()
                });

                break;
        }
    }

    onMessage = (id: string, session: Session, payload: any) => {
        // console.log("Momento.onMessage");
        // console.log(payload);

        this.app.ports.mmOnMessage.send({
            id: id,
            session: session,
            payload: payload
        });
    }

    // === Lists
    pushList = async (args: PushListArgs) => {
        //console.log("Momento.pushList");

        const pushResponse =
            await args.session.cacheClient.listPushBack(
                args.session.cache,
                args.list,
                JSON.stringify(args.payload));

        switch (pushResponse.type) {
            case CacheListPushBackResponse.Success:
                //console.log(`Value '${args.payload}' added successfully to back of list '${args.list}'`);
                break;
            case CacheListPushBackResponse.Error:
                //console.log("Momento.pusList.Error");

                this.app.ports.mmResponse.send({
                    id: args.id,
                    type_: "Error",
                    response: pushResponse.innerException()
                });
        }

        this.app.ports.mmResponse.send({
            id: args.id,
            type_: "Ok",
            response: args.session
        });
    }

    popList = async (args: PopListArgs) => {
        //console.log("Momento.popList");

        const popResponse =
            await args.session.cacheClient.listPopFront(
                args.session.cache,
                args.list);

        switch (popResponse.type) {
            case CacheListPopFrontResponse.Hit:
                //console.log(`Value '${popResponse.value()}' popped from list '${args.list}'`);

                this.app.ports.mmResponse.send({
                    id: args.id,
                    type_: "Item",
                    response: JSON.parse(popResponse.value())
                });

                break;

            case CacheListPopFrontResponse.Miss:
                //console.log(`No value  popped from list '${args.list}'`);

                this.app.ports.mmResponse.send({
                    id: args.id,
                    type_: "ItemNotFound",
                    response: args.session
                });

                break;
            case CacheListPopFrontResponse.Error:
                //console.log("Momento.popList.Error");

                this.app.ports.mmResponse.send({
                    id: args.id,
                    type_: "Error",
                    response: popResponse.innerException()
                });
        }

    }

    // == Webhooks
    createWebhook = async (args: CreateWebhookArgs) => {
        // console.log("Momento.createWebhook");
        // console.log(args);

        const webhookResponse =
            await args.session.topicClient.putWebhook(
                args.session.cache,
                args.name,
                {
                    topicName: args.topic,
                    destination: args.url
                });

        switch (webhookResponse.type) {
            case PutWebhookResponse.Success:
                //console.log('Successfully put webhook');
                break;

            case PutWebhookResponse.Error:
                // console.log("Momento.createWebhook.Error");
                // console.error(webhookResponse.innerException());

                this.app.ports.mmResponse.send({
                    id: args.id,
                    type_: "Error",
                    response: webhookResponse.innerException()
                });
        }

        this.app.ports.mmResponse.send({
            id: args.id,
            type_: "Ok",
            response: args.session
        });
    }
}
