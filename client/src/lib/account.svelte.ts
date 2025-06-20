import { Account } from "starknet";
import Controller from "@cartridge/controller";

let p1AccountStore = $state<Account>()
let p2AccountStore = $state<Account>()
let p1Username = $state<string>()
let p2Username = $state<string>()
let selectedAccount = $state<"p1" | "p2" | null>(null)

//let contract_address = "0x049d36570d4e46f48e99674bd3fcc8463d4990949b4c6bb434ee877b1830a794"
const controller = new Controller({
    defaultChainId: "0x534e5f5345504f4c4941",
    chains: [
        {
            rpcUrl: "https://api.cartridge.gg/x/starknet/sepolia"
        }
    ]});



export const account = {
        get p1Account() {
            return p1AccountStore;
        },
        get p1Username() {
            return p1Username;
        },
        get p2Account() {
            return p2AccountStore;
        },
        get p2Username() {
            return p2Username;
        },
        get selectedAccount() {
            return selectedAccount === "p1" ? p1AccountStore : selectedAccount === "p2" ? p2AccountStore : null;
        },
        get selectedUsername() {
            return selectedAccount === "p1" ? p1Username : selectedAccount === "p2" ? p2Username : null;
        },
        switchAccount() {
            if (selectedAccount === "p1") {
                selectedAccount = "p2";
            } else {
                selectedAccount = "p1";
            }
        },
        async connectP1() {
            const res = await controller.connect();
            if (res) {
                p1AccountStore = res;
                p1Username = await controller.username()!;
                console.log(p1AccountStore, p1Username);
            }
        },
        async disconnectP1() {
            await controller.disconnect();
            p1AccountStore = undefined;
            p1Username = undefined;
        },
        async connectP2() {
            const res = await controller.connect();
            if (res) {
                p2AccountStore = res;
                p2Username = await controller.username()!;
                console.log(p2AccountStore, p2Username);
            }
        },
        async disconnectP2() {
            await controller.disconnect();
            p2AccountStore = undefined;
            p2Username = undefined;
        }
}

