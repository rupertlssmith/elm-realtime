import {
    CacheClient,
    CredentialProvider,
    ListCachesResponse
} from "@gomomento/sdk";
import {Resource} from "sst";

const momentoSecret = JSON.parse(Resource.MomentoApiKey.value);

export async function main(event, context) {
    // Connect to the Momento Cache.
    const cacheClient = new CacheClient({
        credentialProvider: CredentialProvider.fromString({apiKey: momentoSecret.apiKey}),
        defaultTtlSeconds: 60,
    });

    const result = await cacheClient.listCaches();
    switch (result.type) {
        case ListCachesResponse.Success:
            break;
        case ListCachesResponse.Error:
            return {
                statusCode: 500,
                body: JSON.stringify({
                    message: 'listCaches Error',
                    error: result.innerException()
                }, null, 4),
            };
    }

    result
        .getCaches()
        .map(c => cacheClient.deleteCache(c.getName()));

    return {
        statusCode: 200,
        body: 'Ok',
    };
}
