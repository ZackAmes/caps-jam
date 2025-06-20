import { Account } from "starknet";
import Controller from "@cartridge/controller";

let accountStore = $state<Account>()
let username = $state<string>()

//let contract_address = "0x049d36570d4e46f48e99674bd3fcc8463d4990949b4c6bb434ee877b1830a794"
const controller = new Controller({
    defaultChainId: "0x534e5f5345504f4c4941",
    chains: [
        {
            rpcUrl: "https://api.cartridge.gg/x/starknet/sepolia"
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
            const res = await controller.connect();
            if (res) {
                accountStore = res;
                username = await controller.username()!;
                console.log(account, username);
            }
        },
        async disconnect() {
            await controller.disconnect();
            accountStore = undefined;
            username = undefined;
        }
    
}

