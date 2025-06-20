import { account } from "./account.svelte";
import { Contract, type Abi } from "starknet";
import manifest from "../../../contracts/manifest_sepolia.json";
import { RpcProvider } from "starknet";
import { planetelo } from "./planetelo.svelte";
import type { Game, Cap } from "./bindings/models.gen"


let rpc = new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/starknet/sepolia"
})
let caps_contract = new Contract(
    manifest.contracts[0].abi,
    manifest.contracts[0].address,
    rpc
).typedv2(manifest.contracts[0].abi as Abi)

let game_state = $state<{game: Game, caps: Array<Cap>}>()

export const caps = {

    get_game: async () => {
        if (planetelo.current_game_id) {
            let res = (await caps_contract.get_game(planetelo.current_game_id)).unwrap()
            game_state = { game: res[0], caps: res[1] }
            console.log(game_state)
        }
    },

    get_cap_at: (x: number, y: number) => {
        return game_state?.caps.find(cap => cap.position.x == x && cap.position.y == y)
    },

    get game_state() {
        return game_state;
    }
    

}