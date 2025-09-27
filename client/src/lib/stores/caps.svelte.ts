import { account } from "./account.svelte";
import { CairoOption, CairoCustomEnum, CallData, Contract, type Abi, CairoOptionVariant } from "starknet";
import manifest from "../../../../contracts/manifest_sepolia.json";
import { RpcProvider } from "starknet";
import { planetelo } from "./planetelo.svelte";
import type { Game, Cap, Action, ActionType, CapType, Vec2, Effect } from "./../dojo/models.gen"
import { push } from 'svelte-spa-router'
import { DojoProvider } from "@dojoengine/core"
import { setupWorld } from "../dojo/contracts.gen"

let dojoProvider = new DojoProvider(
    manifest, "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_9"
)

let client = setupWorld(dojoProvider)

let rpc = new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/starknet/sepolia/rpc/v0_8"
})
let caps_contract = new Contract(
    manifest.contracts[0].abi,
    manifest.contracts[0].address,
    rpc
).typedv2(manifest.contracts[0].abi as Abi)

let caps_planetelo_contract = new Contract(
    manifest.contracts[2].abi,
    manifest.contracts[2].address,
    rpc
).typedv2(manifest.contracts[2].abi as Abi)

let game_state = $state<{game: Game, caps: Array<Cap>, effects: Array<Effect>}>()

let current_move = $state<Array<Action>>([])

let initial_state = $state<{game: Game, caps: Array<Cap>, effects: Array<Effect>}>()
let selected_cap = $state<Cap | null>(null)
let inspected_cap = $state<Cap | null>(null)

let planetelo_game_state = $state<{game: Game, caps: Array<Cap>, effects: Array<Effect>}>()
let agent_game_state = $state<{game: Game, caps: Array<Cap>, effects: Array<Effect>}>()

// Add state for cap data popup positions
let selected_cap_render_position = $state<{x: number, y: number} | null>(null)
let inspected_cap_render_position = $state<{x: number, y: number} | null>(null)

let selected_cap_position = $derived(selected_cap?.location.unwrap())

let popup_state = $state<{
    visible: boolean,   
    position: {x: number, y: number} | null,
    render_position: {x: number, y: number} | null,
    available_actions: Array<{type: 'move' | 'attack' | 'ability' | 'deselect', label: string}> 
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
        return [{x: selected_cap_position?.x, y: selected_cap_position?.y}]
    }
    else if (target_type == 'TeamCap') {
        let res = []
        let in_range = get_targets_in_range({x: Number(selected_cap_position?.x), y: Number(selected_cap_position?.y)}, ability_range!)
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
        let in_range = get_targets_in_range({x: Number(selected_cap_position?.x), y: Number(selected_cap_position?.y)}, ability_range!)
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
        let in_range = get_targets_in_range({x: Number(selected_cap_position?.x), y: Number(selected_cap_position?.y)}, ability_range!)
        for (let val of in_range) {
            let cap_at = caps.get_cap_at(val.x, val.y)
            if (cap_at) {
                res.push(val)
            }
        }
        return res
    }
    else if (target_type == 'AnySquare') {
        let in_range = get_targets_in_range({x: Number(selected_cap_position?.x), y: Number(selected_cap_position?.y)}, ability_range!)
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

    let in_range = get_targets_in_range({x: Number(selected_cap_position?.x), y: Number(selected_cap_position?.y)}, attack_range!)
    in_range = in_range.filter(val => caps.get_cap_at(val.x, val.y) && caps.get_cap_at(val.x, val.y)?.owner != account.account?.address)
    return in_range
}


let cap_types = $state<Array<CapType>>([])

let valid_ability_targets = $derived(get_valid_ability_targets(Number(selected_cap?.cap_type)))

let valid_moves = $derived(get_moves_in_range({x: Number(selected_cap?.location.unwrap()!.position.x), y: Number(selected_cap?.location.unwrap()!.position.y)}, cap_types.find(cap_type => cap_type.id == selected_cap?.cap_type)?.move_range!))

let valid_attacks = $derived(get_valid_attacks(Number(selected_cap?.cap_type)))

let max_energy = $derived(Number(game_state?.game.turn_count) + 2)
let energy = max_energy

let selected_team = $state<number | null>(null)

const get_simulated_state = async () => {
    console.log(game_state)
    console.log(game_state.game)
    console.log(game_state.caps)
    console.log(game_state.effects)
    console.log(current_move)

    let new_state;
    if (game_state.effects) {
        let effects_arg = new CairoOption<Array<Effect>>(CairoOptionVariant.Some, game_state.effects)
        new_state = await caps_contract.simulate_turn(game_state.game, game_state.caps, effects_arg, current_move)
    }
    else {
        let effects_arg = new CairoOption<Array<Effect>>(CairoOptionVariant.None)
        new_state = await caps_contract.simulate_turn(game_state.game, game_state.caps, effects_arg, current_move)
    }
    new_state = new_state.unwrap()
    console.log(new_state)
    return new_state
}


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
    
    let actions: Array<{type: 'move' | 'attack' | 'ability' | 'deselect', label: string}> = []
    
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

const execute_action = (action_type: 'move' | 'attack' | 'ability' | 'deselect', position: {x: number, y: number}) => {
    if (action_type === 'deselect') {
        selected_cap = null
        selected_cap_render_position = null
        popup_state.visible = false
        popup_state.position = null
        popup_state.available_actions = []
        return
    }

    if (!selected_cap) return

    console.log(game_state)
    
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
        if (selected_cap.location.unwrap()!.position.x == position.x) {
            if (BigInt(position.y) > BigInt(selected_cap.location.unwrap()!.position.y)) {
                cairo_action_type = new CairoCustomEnum({ Move: {x: 2, y: BigInt(position.y) - BigInt(selected_cap.location.unwrap()!.position.y)}, Attack: undefined})
            } else {
                cairo_action_type = new CairoCustomEnum({ Move: {x: 3, y: BigInt(selected_cap.location.unwrap()!.position.y) - BigInt(position.y)}, Attack: undefined})
            }
        } else if (selected_cap.location.unwrap()!.position.y == position.y) {
            if (BigInt(position.x) > BigInt(selected_cap.location.unwrap()!.position.x)) {
                cairo_action_type = new CairoCustomEnum({ Move: {x: 0, y: BigInt(position.x) - BigInt(selected_cap.location.unwrap()!.position.x)}, Attack: undefined})
            } else {
                cairo_action_type = new CairoCustomEnum({ Move: {x: 1, y: BigInt(selected_cap.location.unwrap()!.position.x) - BigInt(position.x)}, Attack: undefined})
            }
        }
        
        energy -= move_cost
        selected_cap.location = new CairoCustomEnum({Board: {x: BigInt(position.x), y: BigInt(position.y)}})
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

    // Navigate to game instead of setting state directly - the tentacles guide the way! 🐙
    go_to_game: (id: number) => {
        push(`/game/${id}`)
    },
    
    // Load game data when viewing a specific game (called from GameView component)
    get_game: async (id: number) => {
        console.log('getting game', id)
        let res = (await caps_contract.get_game(id)).unwrap()
        if (game_state != initial_state) {
            initial_state = { game: res[0], caps: res[1], effects: res[2] }
        }
        else {
            initial_state = { game: res[0], caps: res[1], effects: res[2] }
        }

        if (!game_state || initial_state.game.turn_count > game_state.game.turn_count) {
            game_state = initial_state
        }

        if (id == planetelo.planetelo_game_id) {
            planetelo_game_state = game_state
        }
        
        if (planetelo.agent_game_id) {
            let agent_game_state = await caps_contract.get_game(planetelo.agent_game_id)
            agent_game_state = agent_game_state.unwrap()
            agent_game_state = { game: agent_game_state[0], caps: agent_game_state[1], effects: agent_game_state[2] }
        }

        planetelo.set_current_game_id(id);
        console.log(game_state)
        for (let cap of game_state?.caps || []) {
            if (!cap_types.find(cap_type => cap_type.id == cap.cap_type)) {
                let cap_type = (await caps_contract.get_cap_data(0, cap.cap_type)).unwrap()
                cap_types.push(cap_type)
            }
        }
        energy = max_energy;
        selected_team = await caps_planetelo_contract.get_player_team(account.account!.address);
    },

    select_team: async (team: number) => {
        await client.planetelo.selectTeam(account.account!, team)

        selected_team = team
    },

    get selected_team() {
        return selected_team
    },

    get_cap_at: (x: number, y: number) => {
        return game_state?.caps.find(cap => {
            const location_variant = cap.location.activeVariant();
            if (location_variant === 'Board') {
                console.log('piece found')
                const board_position = cap.location.unwrap();
                console.log(board_position)
                return board_position.x == x && board_position.y == y;
            }
            return false;
        })
    },

    take_turn: async () => {
        if (game_state && account.account && current_move.length > 0) {
            console.log('sending current_move', current_move)
            let calldata = client.actions.buildTakeTurnCalldata(game_state.game.id, current_move)
            console.log(calldata)
            let res = await client.actions.takeTurn(account.account!, game_state.game.id, current_move)
            console.log(res)
            current_move = []
            selected_cap = null
            energy = max_energy;
        }
    },
    
    reset: () => {
        game_state = undefined;
        current_move = [];
        energy = max_energy;
        selected_cap = null;
        inspected_cap = null;
        selected_cap_render_position = null;
        inspected_cap_render_position = null;
    },

    reset_move: () => {
        current_move = []
        selected_cap = null
        selected_cap_render_position = null
        inspected_cap = null
        inspected_cap_render_position = null
        energy = max_energy
        game_state = initial_state
        popup_state.visible = false
        popup_state.position = null
        popup_state.available_actions = []
    },

    add_action: async (action: Action) => {
        current_move.push(action)
        await get_simulated_state();
        console.log(current_move)
    },

    handle_click: (position: {x: number, y: number}, e: any) => {
        // If clicking on selected cap
        let selected_cap_location = selected_cap?.location.unwrap();
        if (selected_cap && selected_cap_location?.x == position.x && selected_cap_location?.y == position.y) {
            const cap_type = cap_types.find(c => c.id === selected_cap!.cap_type);
            const ability_target_type = cap_type?.ability_target.activeVariant();

            if (ability_target_type === 'SelfCap') {
                // Show popup with "Use Ability" and "Deselect"
                popup_state = {
                    visible: true,
                    position: position,
                    render_position: {x: e.nativeEvent.screenX, y: e.nativeEvent.screenY},
                    available_actions: [
                        {type: 'ability', label: 'Use Ability'},
                        {type: 'deselect', label: 'Deselect'}
                    ]
                };
            } else {
                // Original behavior: just deselect
                selected_cap = null
                selected_cap_render_position = null
                inspected_cap = null
                inspected_cap_render_position = null
            }
            return;
        }

        console.log(e)
        
        let cap = caps.get_cap_at(position.x, position.y)
        
        // Debug ownership
        if (cap) {
            console.log('Clicked cap:', cap)
            console.log('Cap owner:', cap.owner)
            console.log('Account address:', BigInt(account.account?.address!))
            console.log('Ownership check:', BigInt(cap.owner) == BigInt(account.account?.address || 0))
        }
        
        // If no cap selected and clicking on own cap, select it
        if (!selected_cap && cap && BigInt(cap.owner) == BigInt(account.account?.address || 0)) {
            selected_cap = cap
            selected_cap_render_position = {x: e.nativeEvent.screenX, y: e.nativeEvent.screenY}
            inspected_cap = null
            inspected_cap_render_position = null
            if (energy === 0) {
                energy = max_energy
            }
            return
        }
        
        // If clicking on an opponent's cap (regardless of whether we have a selected cap)
        if (cap && BigInt(cap.owner) != BigInt(account.account?.address || 0)) {
            // If this is the same cap that's already inspected, close it
            if (inspected_cap && inspected_cap.id === cap.id) {
                inspected_cap = null;
                inspected_cap_render_position = null;
            } else {
                // Inspect the new opponent cap
                inspected_cap = cap;
                inspected_cap_render_position = {x: e.nativeEvent.screenX, y: e.nativeEvent.screenY};
            }
        } else if (!cap) {
            // Clicking on empty space - clear inspected cap
            inspected_cap = null;
            inspected_cap_render_position = null;
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

    close_inspected_cap: () => {
        inspected_cap = null
        inspected_cap_render_position = null
    },

    get selected_cap() {
        return selected_cap
    },

    get selected_cap_position() {
        return selected_cap_position
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

    get inspected_cap() {
        return inspected_cap
    },

    get selected_cap_render_position() {
        return selected_cap_render_position
    },

    get inspected_cap_render_position() {
        return inspected_cap_render_position
    },

    get planetelo_game_state() {
        return planetelo_game_state
    },

    get agent_game_state() {
        return agent_game_state
    },

}
