import { Account } from "starknet";
import Controller from "@cartridge/controller";
import { planetelo } from "./planetelo.svelte";
import { caps } from "./caps.svelte";

let accountStore = $state<Account>()
let username = $state<string>()

//let contract_address = "0x049d36570d4e46f48e99674bd3fcc8463d4990949b4c6bb434ee877b1830a794"
const controller = new Controller({
    defaultChainId: "0x534e5f5345504f4c4941",
    chains: [
        {
            rpcUrl: "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9"
        }
    ]});


export const account = {
        get account() {
            return accountStore;
        },
        get username() {
            return username;
        },
        async connect() {
            controller.probe();
            const res = await controller.connect();
            if (res) {
                accountStore = res;
                username = await controller.username()!;
                console.log(accountStore)
                console.log(accountStore, username);
            }
        },
        async disconnect() {
            await controller.disconnect();
            planetelo.reset();
            caps.reset();
            accountStore = undefined;
            username = undefined;
        },
}

