import { account } from "./account.svelte";
import { Contract, type Abi } from "starknet";
import planetelo_manifest from "../dojo/planetelo_sepolia_manifest.json";
import { RpcProvider } from "starknet";
import { shortString } from "starknet";
import { caps } from "./caps.svelte";
import caps_planetelo_manifest from "../../../../contracts/manifest_sepolia.json";
import { get } from "svelte/store";
import type { CustomGames } from "../dojo/models.gen";
import { push } from 'svelte-spa-router'
import { setupWorld } from "../dojo/contracts.gen";
import { DojoProvider } from "@dojoengine/core";

let rpc = new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_8"
})
let dojoProvider = new DojoProvider(
    caps_planetelo_manifest, "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_8"
)
let caps_client = setupWorld(dojoProvider)
let plantelo_contract = new Contract(
    planetelo_manifest.contracts[0].abi,
    planetelo_manifest.contracts[0].address,
    rpc
).typedv2(planetelo_manifest.contracts[0].abi as Abi)

let caps_planetelo_contract = new Contract(
    caps_planetelo_manifest.contracts[2].abi,
    caps_planetelo_manifest.contracts[2].address,
    rpc
).typedv2(caps_planetelo_manifest.contracts[2].abi as Abi)

let game_id = shortString.encodeShortString("caps");

let queue_status = $state<number | null>(null)
let current_game_id = $state<number | null>(null)
let agent_game_id = $state<number | null>(null)
let planetelo_game_id = $state<number | null>(null)
let invites = $state<Array<number>>([])
let custom_games = $state<Array<CustomGames>>([])
let elo = $state<number | null>(null)
let queue_length = $state<number | null>(null)

export const planetelo = {
    address: planetelo_manifest.contracts[0].address,
    get_status: async () => {
        console.log(account.account!.address)
        let status = parseInt(await plantelo_contract.get_status(account.account!.address, game_id, "0x0"));
        console.log(status)
        let elo_res = parseInt(await plantelo_contract.get_elo(account.account!.address, game_id, "0x0"));
        elo = elo_res;
        let queue_length = parseInt(await plantelo_contract.get_queue_length(game_id, "0"));
        queue_length = queue_length;
        queue_status = status;

        let res = {status, elo, queue_length, game_id, winner: null};
        let agent_game_id = await caps_planetelo_contract.get_player_game_id(account.account!.address);
        console.log('agent_game_id', agent_game_id)
        agent_game_id = agent_game_id;

        if (status == 2) {
            let current_game_id = await plantelo_contract.get_player_game_id(account.account!.address, game_id, "0x0");
            planetelo_game_id = current_game_id;
            res.game_id = current_game_id;
        }
        else if (agent_game_id) {
            current_game_id = agent_game_id;
        }
        invites = await planetelo.get_player_invites();
        custom_games = await planetelo.get_player_custom_games();
        // Don't auto-navigate to game - let user choose when to view game
        console.log(res)
        return res;
    },

    update_status: async () => {
        if (account.account) {
            let status = await planetelo.get_status();
            console.log(status)
            queue_status = status.status;
            if (status.status == 2) {
                planetelo_game_id = await plantelo_contract.get_player_game_id(account.account!.address, game_id, "0x0");
                current_game_id = planetelo_game_id;
            }
            agent_game_id = await caps_planetelo_contract.get_player_game_id(account.account!.address);
            queue_length = await plantelo_contract.get_queue_length(game_id, "0");
        }
    },

    play_agent: async () => {
        if (account.account) {
            let res = await caps_client.planetelo.playAgent(account.account!);
            console.log(res);
            planetelo.update_status();
        }
    },

    settle_agent_game: async () => {
        if (account.account) {
            let res = await caps_client.planetelo.settleAgentGame(account.account!);
            console.log(res);
            planetelo.update_status();
        }
    },



    handleQueue: async () => {
        console.log(planetelo.address);
        console.log(account.account?.address)
        let res = await account.account?.execute(
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
        let res = await account.account?.execute(
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
        console.log(current_game_id)
        if (account.account ) {
            let res = await account.account?.execute(
                [{
                    contractAddress: planetelo.address,
                    entrypoint: 'settle',
                    calldata: [game_id, current_game_id!]
                }]
            );
            console.log(res);
            planetelo.update_status();
        }
    },

    refresh_status: async () => {
        if (account.account) {
            let res = await account.account?.execute(
                [{
                    contractAddress: planetelo.address,
                    entrypoint: 'refresh_status',
                    calldata: [game_id, "0"]
                }]
            );
            console.log(res);
        }
    },

    reset: async () => {

        current_game_id = null;
        queue_status = null;
        elo = null;
        agent_game_id = null;
        planetelo_game_id = null;

    },

    set_current_game_id: (id: number) => {
        current_game_id = id;
    },

    // Navigate to the other available game - surfing the URL waves! 🐙
    switch_current_game: () => {
        console.log('switching current game')
        console.log(planetelo_game_id)
        console.log(agent_game_id)
        console.log(current_game_id)
        if (!planetelo_game_id || !agent_game_id) {
            planetelo.get_status();
            return;
        }
        if (current_game_id == agent_game_id) {
            push(`/game/${planetelo_game_id}`)
        }
        else {
            push(`/game/${agent_game_id}`)
        }
    },

    get_player_invites: async () => {
        let invites = await caps_planetelo_contract.get_player_invites(account.account!.address);
        console.log(invites)
        return invites;
    },

    get_player_custom_games: async () => {
        let games = await caps_planetelo_contract.get_player_custom_games(account.account!.address);
        console.log(games)
        return games;
    },

    accept_invite: async (invite_id: number) => {
        let res = await caps_client.planetelo.acceptInvite(account.account!, invite_id);
        console.log(res);
        planetelo.update_status();
    },

    decline_invite: async (invite_id: number) => {
            let res = await caps_client.planetelo.declineInvite(account.account!, invite_id);
        console.log(res);
        planetelo.update_status();
    },

    settle_custom_game: async (game_id: number) => {
        let res = await caps_client.planetelo.settleCustomGame(account.account!, game_id);
        console.log(res);
        planetelo.update_status();
    },

    get_player_stats: async () => {
        let stats = await caps_planetelo_contract.get_player_stats(account.account!.address);
        console.log(stats)
        return stats;
    },

    get queue_status() {
        return queue_status;
    },

    get current_game_id() {
        return current_game_id;
    },

    get agent_game_id() {
        return agent_game_id;
    },

    get planetelo_game_id() {
        return planetelo_game_id;
    },

    get elo() {
        return elo;
    },

    get invites() {
        return invites;
    },

    get custom_games() {
        return custom_games;
    },

    get queue_length() {
        return queue_length;
    }

}