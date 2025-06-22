import { account } from "./account.svelte";
import { CairoCustomEnum, CallData, Contract, type Abi } from "starknet";
import manifest from "../../../../contracts/manifest_sepolia.json";
import { RpcProvider } from "starknet";
import { planetelo } from "./planetelo.svelte";
import type { Game, Cap, Action, ActionType, CapType, Vec2 } from "./../dojo/models.gen"


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

let initial_state = $state<{game: Game, caps: Array<Cap>}>()
let selected_cap = $state<Cap | null>(null)
let popup_state = $state<{
    visible: boolean,
    position: {x: number, y: number} | null,
    render_position: {x: number, y: number} | null,
    available_actions: Array<{type: 'move' | 'attack' | 'ability', label: string}> 
}>({
    visible: false,
    position: null,
    render_position: null,
    available_actions: []
})

const get_valid_ability_targets = (id: number) => {
    let cap_type = cap_types.find(cap_type => cap_type.id == selected_cap?.cap_type)
    console.log(cap_type)
    let target_type = cap_type?.ability_target.activeVariant();
    let ability_range = cap_type?.ability_range
    console.log(target_type)
    console.log(ability_range)
    if (target_type == 'None') {
        return []
    }
    else if (target_type == 'SelfCap') {
        return [{x: selected_cap?.position.x, y: selected_cap?.position.y}]
    }
    else if (target_type == 'TeamCap') {
        let res = []
        let in_range = get_targets_in_range({x: Number(selected_cap?.position.x), y: Number(selected_cap?.position.y)}, ability_range!)
        console.log(in_range)
        for (let val of in_range) {
            let cap_at = caps.get_cap_at(val.x, val.y)
            if (cap_at && cap_at.owner == account.account?.address) {
                res.push(val)
            }
        }
        return res
    }
    else if (target_type == 'OpponentCap') {
        let res = []
        let in_range = get_targets_in_range({x: Number(selected_cap?.position.x), y: Number(selected_cap?.position.y)}, ability_range!)
        for (let val of in_range) {
            let cap_at = caps.get_cap_at(val.x, val.y)
            if (cap_at && cap_at.owner != account.account?.address) {
                res.push(val)
            }
        }
        return res
    }
    else if (target_type == 'AnyCap') {
        let res = []
        let in_range = get_targets_in_range({x: Number(selected_cap?.position.x), y: Number(selected_cap?.position.y)}, ability_range!)
        for (let val of in_range) {
            let cap_at = caps.get_cap_at(val.x, val.y)
            if (cap_at) {
                res.push(val)
            }
        }
        return res
    }
    else if (target_type == 'AnySquare') {
        let in_range = get_targets_in_range({x: Number(selected_cap?.position.x), y: Number(selected_cap?.position.y)}, ability_range!)
        return in_range
    }
    return []
}

const get_moves_in_range = (position: {x: number, y: number}, range: Vec2 | undefined) => {
    if (!range) {
        return []
    }
    let res = [];
    let i = 1;
    console.log(range)
    while (i <= Number(range.x)) {
        if (position.x + i < 7) {
            let cap_at = caps.get_cap_at(position.x + i, position.y)
            console.log(cap_at)
            if (!cap_at) {
                res.push({x: position.x + i, y: position.y})
            }
        }
        if (position.x - i >= 0) {
            let cap_at = caps.get_cap_at(position.x - i, position.y)
            console.log(cap_at)
            if (!cap_at) {
                res.push({x: position.x - i, y: position.y})
            }
        }
        i++;
    }
    i = 1;
    while (i <= Number(range.y)) {
        if (position.y + i < 7) {
            let cap_at = caps.get_cap_at(position.x, position.y + i)
            if (!cap_at) {
                res.push({x: position.x, y: position.y + i})
            }
        }
        if (position.y - i >= 0) {
            let cap_at = caps.get_cap_at(position.x, position.y - i)
            if (!cap_at) {
                res.push({x: position.x, y: position.y - i})
            }
        }
        i++;
    }
    return res
}

const get_valid_attacks = (id: number) => {
    let cap_type = cap_types.find(cap_type => cap_type.id == selected_cap?.cap_type)
    let attack_range = cap_type?.attack_range
    let in_range = get_targets_in_range({x: Number(selected_cap?.position.x), y: Number(selected_cap?.position.y)}, attack_range!)
    in_range = in_range.filter(val => caps.get_cap_at(val.x, val.y) && caps.get_cap_at(val.x, val.y)?.owner != account.account?.address)
    return in_range
}


let cap_types = $state<Array<CapType>>([])

let valid_ability_targets = $derived(get_valid_ability_targets(Number(selected_cap?.cap_type)))

let valid_moves = $derived(get_moves_in_range({x: Number(selected_cap?.position.x), y: Number(selected_cap?.position.y)}, cap_types.find(cap_type => cap_type.id == selected_cap?.cap_type)?.move_range!))

let valid_attacks = $derived(get_valid_attacks(Number(selected_cap?.cap_type)))

let max_energy = $derived(Number(game_state?.game.turn_count) + 2)
let energy = $state(max_energy)



const get_targets_in_range = (position: {x: number, y: number}, range: Array<Vec2> | undefined) => {
    if (!range) {
        return []
    }
    let res = []
    for (let val of range) {
            res.push({x: position.x + Number(val.x), y: position.y + Number(val.y)})
        
            res.push({x: position.x - Number(val.x), y: position.y - Number(val.y)})
        
            res.push({x: position.x + Number(val.x), y: position.y - Number(val.y)})
        
            res.push({x: position.x - Number(val.x), y: position.y + Number(val.y)})
        
    }
    return res
}

const get_available_actions_at_position = (position: {x: number, y: number}) => {
    if (!selected_cap) return []
    
    let actions: Array<{type: 'move' | 'attack' | 'ability', label: string}> = []
    
    // Check if position is a valid move
    let is_valid_move = valid_moves.some(move => move.x === position.x && move.y === position.y)
    if (is_valid_move) {
        actions.push({type: 'move', label: 'Move'})
    }
    
    // Check if position is a valid attack
    let is_valid_attack = valid_attacks.some(attack => attack.x === position.x && attack.y === position.y)
    if (is_valid_attack) {
        actions.push({type: 'attack', label: 'Attack'})
    }
    
    // Check if position is a valid ability target
    let is_valid_ability = valid_ability_targets.some(target => target.x === position.x && target.y === position.y)
    if (is_valid_ability) {
        actions.push({type: 'ability', label: 'Use Ability'})
    }
    
    return actions
}

const execute_action = (action_type: 'move' | 'attack' | 'ability', position: {x: number, y: number}) => {
    if (!selected_cap) return
    
    let cap_type = cap_types.find(cap_type => cap_type.id == selected_cap?.cap_type)
    let move_cost = Number(cap_type?.move_cost)
    let attack_cost = Number(cap_type?.attack_cost)
    let ability_cost = Number(cap_type?.ability_cost)
    
    if (action_type === 'move') {
        if (energy < move_cost) {
            alert(`Not enough energy! Need ${move_cost} but only have ${energy}`)
            return
        }
        
        let cairo_action_type;
        if (selected_cap.position.x == position.x) {
            if (BigInt(position.y) > BigInt(selected_cap.position.y)) {
                cairo_action_type = new CairoCustomEnum({ Move: {x: 2, y: BigInt(position.y) - BigInt(selected_cap.position.y)}, Attack: undefined})
            } else {
                cairo_action_type = new CairoCustomEnum({ Move: {x: 3, y: BigInt(selected_cap.position.y) - BigInt(position.y)}, Attack: undefined})
            }
        } else if (selected_cap.position.y == position.y) {
            if (BigInt(position.x) > BigInt(selected_cap.position.x)) {
                cairo_action_type = new CairoCustomEnum({ Move: {x: 0, y: BigInt(position.x) - BigInt(selected_cap.position.x)}, Attack: undefined})
            } else {
                cairo_action_type = new CairoCustomEnum({ Move: {x: 1, y: BigInt(selected_cap.position.x) - BigInt(position.x)}, Attack: undefined})
            }
        }
        
        energy -= move_cost
        selected_cap.position = position;
        console.log(selected_cap)
        caps.add_action({cap_id: selected_cap.id, action_type: cairo_action_type!})
    }
    else if (action_type === 'attack') {
        if (energy < attack_cost) {
            alert(`Not enough energy! Need ${attack_cost} but only have ${energy}`)
            return
        }
        
        let cairo_action_type = new CairoCustomEnum({ Move: undefined, Attack: {x: BigInt(position.x), y: BigInt(position.y)}, Ability: undefined})
        energy -= attack_cost
        caps.add_action({cap_id: selected_cap.id, action_type: cairo_action_type})
    }
    else if (action_type === 'ability') {
        if (energy < ability_cost) {
            alert(`Not enough energy! Need ${ability_cost} but only have ${energy}`)
            return
        }
        
        let cairo_action_type = new CairoCustomEnum({ Move: undefined, Attack: undefined, Ability: {x: BigInt(position.x), y: BigInt(position.y)}})
        energy -= ability_cost
        caps.add_action({cap_id: selected_cap.id, action_type: cairo_action_type})
    }
    
    // Close popup after action
    popup_state.visible = false
    popup_state.position = null
    popup_state.available_actions = []
}

export const caps = {

    get_game: async (id: number) => {
        console.log('getting game', id)
            let res = (await caps_contract.get_game(id)).unwrap()
            game_state = { game: res[0], caps: res[1] } 
            initial_state = { game: res[0], caps: res[1] }
            planetelo.set_current_game_id(id);
            console.log(game_state)
            for (let cap of game_state.caps) {
                if (!cap_types.find(cap_type => cap_type.id == cap.cap_type)) {
                    let cap_type = (await caps_contract.get_cap_data(cap.cap_type)).unwrap()
                    cap_types.push(cap_type)
                }
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
    
    reset: () => {
        game_state = undefined;
        current_move = [];
        selected_cap = null;
    },

    reset_move: () => {
        current_move = []
        selected_cap = null
        energy = max_energy
        game_state = initial_state
        popup_state.visible = false
        popup_state.position = null
        popup_state.available_actions = []
    },

    add_action: (action: Action) => {
        current_move.push(action)
        console.log(current_move)
    },

    handle_click: (position: {x: number, y: number}, e: any) => {
        // If clicking on selected cap, deselect it
        if (selected_cap && selected_cap.position.x == position.x && selected_cap.position.y == position.y) {
            selected_cap = null
            return
        }

        console.log(e)
        
        let cap = caps.get_cap_at(position.x, position.y)
        
        // If no cap selected and clicking on own cap, select it
        if (!selected_cap && cap && cap.owner == account.account?.address) {
            selected_cap = cap
            if (energy === 0) {
                energy = max_energy
            }
            return
        } 
        
        // If cap is selected, check for available actions at clicked position
        if (selected_cap) {
            let available_actions = get_available_actions_at_position(position)
            
            if (available_actions.length > 0) {
                // Show popup with available actions

                popup_state = {
                    visible: true,
                    position: position,
                    render_position: {x: e.nativeEvent.screenX, y: e.nativeEvent.screenY},
                    available_actions: available_actions
                }
            }
        }
    },

    execute_action: execute_action,

    close_popup: () => {
        popup_state.visible = false
        popup_state.position = null
        popup_state.available_actions = []
    },

    get selected_cap() {
        return selected_cap
    },

    get game_state() {
        return game_state;
    },

    get cap_types() {
        return cap_types;
    },

    get current_move() {
        return current_move
    },

    get energy() {
        return energy
    },

    get max_energy() {
        return max_energy
    },

    get valid_ability_targets() {
        return valid_ability_targets
    },

    get valid_moves() {
        return valid_moves
    },

    get valid_attacks() {
        return valid_attacks
    },

    get popup_state() {
        return popup_state
    },

}
