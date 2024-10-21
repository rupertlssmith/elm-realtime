import {SSTConfig} from "sst";
import {ChatStack} from "./stacks/MyStack";

export default {
    config(_input) {
        return {
            name: "00-vpc",
            region: "eu-west-2",
            profile: _input.stage === "production" ? "thesett-prod" : "thesett-dev",
        };
    },
    stacks(app) {
        app.setDefaultFunctionProps({
            runtime: "python3.9",
        });
        app.stack(ChatStack);
    }
} satisfies SSTConfig;
