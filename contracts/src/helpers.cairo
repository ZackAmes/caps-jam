use dojo::model::{ModelStorage};
use caps::models::game::{Game, GameTrait, Action, ActionType};
use caps::models::cap::{Cap, CapTrait, CapType, TargetType, TargetTypeTrait, Location};
use caps::models::effect::{Effect, EffectTrait, EffectType, EffectTarget, Timing};
use caps::models::set::Set;
use caps_core::sets::set_zero::get_cap_type;
use caps::conversions::{
    caps_array_into_core, caps_array_from_core, effects_array_into_core, effects_array_from_core,
    caps_dict_from_core, caps_dict_into_core, actions_array_into_core,
    GameIntoCore, GameFromCore, CapIntoCore, CapFromCore, EffectIntoCore, EffectFromCore,
};
use starknet::ContractAddress;
use dojo::world::WorldStorage;
use core::dict::Felt252Dict;

pub fn get_player_pieces(
    game_id: u64, player: ContractAddress, world: @WorldStorage,
) -> Array<u64> {
    let mut game: Game = world.read_model(game_id);
    let mut pieces: Array<u64> = ArrayTrait::new();
    let mut i = 0;

    assert!(game.player1 == player || game.player2 == player, "Not in game");

    while i < game.caps_ids.len() {
        let cap: Cap = world.read_model(*game.caps_ids[i]);
        if cap.owner == player.into() {
            pieces.append(cap.id);
        }
        i += 1;
    };

    pieces
}

pub fn get_piece_locations(
    ref game: Game, world: @WorldStorage,
) -> (Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>) {
    let mut locations: Felt252Dict<u64> = Default::default();
    let mut keys: Felt252Dict<Nullable<Cap>> = Default::default();
    let mut i = 0;

    while i < game.caps_ids.len() {
        let cap: Cap = world.read_model(*game.caps_ids[i]);
        let position = cap.get_position();
        if position.is_none() {
            keys.insert(cap.id.into(), NullableTrait::new(cap));
            i+=1;
            continue;
        }
        let position = position.unwrap();
        let index = position.x * 7 + position.y;
        locations.insert(index.into(), cap.id);
        keys.insert(cap.id.into(), NullableTrait::new(cap));
        i += 1;
    };

    (locations, keys)
}

pub fn get_active_effects(
    ref game: Game, world: @WorldStorage,
) -> (Array<Effect>, Array<Effect>, Array<Effect>) {
    let mut start_of_turn_effects: Array<Effect> = ArrayTrait::new();
    let mut move_step_effects: Array<Effect> = ArrayTrait::new();
    let mut end_of_turn_effects: Array<Effect> = ArrayTrait::new();

    let mut i = 0;
    while i < game.effect_ids.len() {
        let effect: Effect = world.read_model((game.id, i));
        match effect.get_timing() {
            Timing::StartOfTurn => { start_of_turn_effects.append(effect); },
            Timing::MoveStep => { move_step_effects.append(effect); },
            Timing::EndOfTurn => { end_of_turn_effects.append(effect); },
            _ => {},
        }
        i += 1;
    };

    (start_of_turn_effects, move_step_effects, end_of_turn_effects)
}

pub fn get_active_effects_from_array(
    game: @Game, effects: @Array<Effect>,
) -> (Array<Effect>, Array<Effect>, Array<Effect>) {
    let core_game: caps_core::types::game::Game = game.clone().into();
    let mut core_effects = ArrayTrait::new();
    for effect in effects {
        core_effects.append((*effect).into());
    };
    
    let (start, step, end) = caps_core::logic::helpers::get_active_effects_from_array(
        @core_game, @core_effects,
    );
    
    (
        effects_array_from_core(start),
        effects_array_from_core(step),
        effects_array_from_core(end),
    )
}

pub fn get_dicts_from_array(caps: @Array<Cap>) -> (Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>) {
    let mut locations: Felt252Dict<u64> = Default::default();
    let mut keys: Felt252Dict<Nullable<Cap>> = Default::default();

    let mut i = 0;
    while i < caps.len() {
        let cap: Cap = *caps.at(i);
        let position = cap.get_position();
        if position.is_none() {
            keys.insert(cap.id.into(), NullableTrait::new(cap));
            i += 1;
            continue;
        }
        let position = position.unwrap();
        let index = position.x * 7 + position.y;
        locations.insert(index.into(), cap.id);
        keys.insert(cap.id.into(), NullableTrait::new(cap));
        i += 1;
    };

    (locations, keys)
}

pub fn update_end_of_turn_effects(
    ref game: Game,
    ref end_of_turn_effects: Array<Effect>,
    locations: Felt252Dict<u64>,
    keys: Felt252Dict<Nullable<Cap>>,
) -> (Game, Array<Effect>, Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>) {
    // Convert to core types
    let mut core_game: caps_core::types::game::Game = game.clone().into();
    let mut core_effects = effects_array_into_core(end_of_turn_effects.clone());
    let mut keys_copy = keys;
    let mut core_keys = caps_dict_into_core(ref keys_copy, @game.caps_ids);
    let mut core_locations = locations;
    
    // Call core function
    let (new_core_game, new_core_effects, new_core_locations, new_core_keys) =
        caps_core::logic::helpers::update_end_of_turn_effects(
        ref core_game, ref core_effects, ref core_locations, ref core_keys,
    );
    
    // Convert back
    let new_game: Game = new_core_game.into();
    let new_effects = effects_array_from_core(new_core_effects);
    let mut new_core_keys_mut = new_core_keys;
    let new_keys = caps_dict_from_core(ref new_core_keys_mut, @new_game.caps_ids);
    
    (new_game, new_effects, new_core_locations, new_keys)
}

pub fn process_actions(
    ref game: Game,
    ref turn: Array<Action>,
    locations: Felt252Dict<u64>,
    ref keys: Felt252Dict<Nullable<Cap>>,
    ref start_of_turn_effects: Array<Effect>,
    ref move_step_effects: Array<Effect>,
    ref end_of_turn_effects: Array<Effect>,
    ref set: Set,
    caller: ContractAddress,
) -> (
    Game, Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>, Array<Effect>, Array<Effect>, Array<Effect>,
) {
    // Convert to core types
    let mut core_game: caps_core::types::game::Game = game.clone().into();
    let mut core_start = effects_array_into_core(start_of_turn_effects.clone());
    let mut core_step = effects_array_into_core(move_step_effects.clone());
    let mut core_end = effects_array_into_core(end_of_turn_effects.clone());
    let mut core_keys = caps_dict_into_core(ref keys, @game.caps_ids);
    let mut core_locations = locations;
    let mut core_turn = actions_array_into_core(turn.clone());
    
    // Call core function
    let (
        new_core_game,
        new_core_locations,
        new_core_keys,
        new_core_start,
        new_core_step,
        new_core_end,
    ) =
        caps_core::logic::process::process_actions(
        ref core_game,
        ref core_turn,
        ref core_locations,
        ref core_keys,
        ref core_start,
        ref core_step,
        ref core_end,
        caller,
    );
    
    // Convert back
    let new_game: Game = new_core_game.into();
    let new_start = effects_array_from_core(new_core_start);
    let new_step = effects_array_from_core(new_core_step);
    let new_end = effects_array_from_core(new_core_end);
    let mut new_core_keys_mut = new_core_keys;
    let new_keys = caps_dict_from_core(ref new_core_keys_mut, @new_game.caps_ids);
    
    (new_game, new_core_locations, new_keys, new_start, new_step, new_end)
}

// Wrapper functions for contract types
pub fn clone_dicts(
    game: @Game, ref locations: Felt252Dict<u64>, ref keys: Felt252Dict<Nullable<Cap>>,
) -> (Game, Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>) {
    // Create new dictionaries
    let mut new_locations: Felt252Dict<u64> = Default::default();
    let mut new_keys: Felt252Dict<Nullable<Cap>> = Default::default();

    let mut i = 0;
    while i < game.caps_ids.len() {
        let cap_id: felt252 = (*game.caps_ids[i]).into();
        let cap: Cap = keys.get(cap_id).deref();
        
        // Copy location
        let pos = cap.get_position();
        if pos.is_some() {
            let position = pos.unwrap();
            new_locations.insert((position.x * 7 + position.y).into(), cap.id);
        }
        
        // Copy cap
        new_keys.insert(cap_id, NullableTrait::new(cap));
        i += 1;
    };

    (game.clone(), new_locations, new_keys)
}

pub fn handle_damage(
    ref game: Game, ref cap: Cap, dmg: u64,
) -> (Game, Cap) {
    // Convert to core types
    let mut core_game: caps_core::types::game::Game = game.clone().into();
    let mut core_cap: caps_core::types::cap::Cap = cap.clone().into();
    
    // Call core function
    let (result_game, result_cap) = caps_core::logic::helpers::handle_damage(
        ref core_game, ref core_cap, dmg,
    );
    
    // Convert back to contract types
    let contract_game: Game = result_game.into();
    let contract_cap: Cap = result_cap.into();
    
    (contract_game, contract_cap)
}

// Re-export check_includes as it doesn't use game types
pub use caps_core::logic::helpers::check_includes;
