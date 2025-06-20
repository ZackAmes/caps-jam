import { account } from "./account.svelte";
import { CairoCustomEnum, CallData, Contract, type Abi } from "starknet";
import manifest from "../../../contracts/manifest_sepolia.json";
import { RpcProvider } from "starknet";
import { planetelo } from "./planetelo.svelte";
import type { Game, Cap, Action, ActionType } from "./bindings/models.gen"


let rpc = new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/starknet/sepolia"
})
let caps_contract = new Contract(
    manifest.contracts[0].abi,
    manifest.contracts[0].address,
    rpc
).typedv2(manifest.contracts[0].abi as Abi)

let game_state = $state<{game: Game, caps: Array<Cap>}>()

let current_move = $state<Array<Action>>([])

let selected_cap = $state<Cap | null>(null)

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

    take_turn: async () => {
        if (game_state && account.account && current_move.length > 0) {
            console.log('sending current_move', current_move)
            let calldata = CallData.compile([game_state.game.id, current_move])
            console.log(calldata)
            let res = await account.account.execute([
                {
                    contractAddress: manifest.contracts[0].address,
                    entrypoint: "take_turn",
                    calldata: calldata
                }
            ])
            console.log(res)
            current_move = []
            selected_cap = null
        }
    },

    reset_move: () => {
        current_move = []
        selected_cap = null
    },

    add_action: (action: Action) => {
        current_move.push(action)
        console.log(current_move)
    },

    handle_click: (position: {x: number, y: number}) => {
        if (selected_cap && selected_cap.position.x == position.x && selected_cap.position.y == position.y) {
            selected_cap = null
          }
          let cap = caps.get_cap_at(position.x, position.y)
          if (!selected_cap && cap && cap.owner == account.account?.address) {
            selected_cap = cap
          } 
          else if (selected_cap && !cap) {
            if (selected_cap.position.x == position.x) {
              if (BigInt(position.y) > BigInt(selected_cap.position.y)) {
                let action_type = new CairoCustomEnum({ Move: {x: 2, y: BigInt(position.y) - BigInt(selected_cap.position.y)}, Attack: undefined})
                caps.add_action({cap_id: selected_cap.id, action_type})
              } else {
                let action_type = new CairoCustomEnum({ Move: {x: 3, y: BigInt(selected_cap.position.y) - BigInt(position.y)}, Attack: undefined})
                caps.add_action({cap_id: selected_cap.id, action_type})
              }
            }
            else if (selected_cap.position.y == position.y) {
              if (BigInt(position.x) > BigInt(selected_cap.position.x)) {
                let action_type = new CairoCustomEnum({ Move: {x: 0, y: BigInt(position.x) - BigInt(selected_cap.position.x)}, Attack: undefined})
                caps.add_action({cap_id: selected_cap.id, action_type})
              } else {
                let action_type = new CairoCustomEnum({ Move: {x: 1, y: BigInt(selected_cap.position.x) - BigInt(position.x)}, Attack: undefined})
                caps.add_action({cap_id: selected_cap.id, action_type})
              }
            }
          } else if (selected_cap && cap && cap.owner != account.account?.address) {
            let action_type = new CairoCustomEnum({ Move: undefined, Attack: {x: BigInt(position.x), y: BigInt(position.y)}})
            caps.add_action({cap_id: selected_cap.id, action_type})
          }
    },

    get selected_cap() {
        return selected_cap
    },

    get game_state() {
        return game_state;
    }
    

}