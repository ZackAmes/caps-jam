import { account } from "./account.svelte";
import { Contract, type Abi } from "starknet";
import planetelo_manifest from "../planetelo_sepolia_manifest.json";
import { RpcProvider } from "starknet";
import { shortString } from "starknet";


let rpc = new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/starknet/sepolia"
})
let plantelo_contract = new Contract(
    planetelo_manifest.contracts[0].abi,
    planetelo_manifest.contracts[0].address,
    rpc
).typedv2(planetelo_manifest.contracts[0].abi as Abi)

let game_id = shortString.encodeShortString("octoguns");

let queue_status = $state<number | null>(null)

export const planetelo = {
    address: planetelo_manifest.contracts[0].address,
    get_status: async () => {
        console.log(plantelo_contract)
        console.log(game_id)
        let status = parseInt(await plantelo_contract.get_player_status(account.selectedAccount!.address, game_id, "0x0"));
        console.log(status)
        let elo = parseInt(await plantelo_contract.get_player_elo(account.selectedAccount!.address, game_id, "0x0"));
        let queue_length = parseInt(await plantelo_contract.get_queue_length(game_id, "0"));

        queue_status = status;

        let res = {status, elo, queue_length, game_id, winner: null};

        if (status == 2) {
            let current_game_id = await plantelo_contract.get_player_game_id(account.selectedAccount!.address, game_id);
            res.game_id = current_game_id;
        }
        return res;
    },

    update_status: async () => {
        if (account.selectedAccount) {
            let status = await planetelo.get_status();
            console.log(status)
            queue_status = status.status;
        }
    },



    handleQueue: async () => {
        console.log(planetelo.address);
        let res = await account.selectedAccount?.execute(
            [{
                contractAddress: planetelo.address,
                entrypoint: 'queue',
                calldata: [game_id, "0"]
            }]
        );

        planetelo.update_status();
        console.log(res);
    },

    handleMatchmake: async () => {
        console.log(planetelo.address);
        let res = await account.selectedAccount?.execute(
            [{
                contractAddress: planetelo.address,
                entrypoint: 'matchmake',
                calldata: [game_id, "0"]
            }]
        );
        console.log(res);
        planetelo.update_status();
    },

    handleSettle: async () => {
        if (account.selectedAccount ) {
            let res = await account.selectedAccount?.execute(
                [{
                    contractAddress: planetelo.address,
                    entrypoint: 'settle',
                    //TODO 
                    calldata: [game_id, 0]
                }]
            );
            console.log(res);
            planetelo.update_status();
        }
    },

    get queue_status() {
        return queue_status;
    }

}