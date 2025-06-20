import { account } from "./account.svelte";
import { Contract, type Abi } from "starknet";
import manifest from "../../../contracts/manifest_sepolia.json";
import { RpcProvider } from "starknet";
import { planetelo } from "./planetelo.svelte";



let rpc = new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/starknet/sepolia"
})
let caps_contract = new Contract(
    manifest.contracts[0].abi,
    manifest.contracts[0].address,
    rpc
).typedv2(manifest.contracts[0].abi as Abi)

let game_state = $state()

export const caps = {

    get_game: async () => {
        let game = await caps_contract.get_game(planetelo.current_game_id)
        console.log(game)
        game_state = game
    }
    

}