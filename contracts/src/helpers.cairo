
use dojo::model::{ModelStorage};
use caps::models::game::{Game, GameTrait};
use caps::models::cap::{Cap};
use caps::models::effect::{Effect, EffectTrait, EffectType, EffectTarget, Timing};
use caps::sets::set_zero::get_cap_type;
use starknet::ContractAddress;
use dojo::world::WorldStorage;
use core::dict::Felt252Dict;

pub fn get_player_pieces(game_id: u64, player: ContractAddress, world: @WorldStorage) -> Array<u64> {
    let mut game: Game = world.read_model(game_id);
    let mut pieces: Array<u64> = ArrayTrait::new();
    let mut i = 0;

    assert!(game.player1 == player || game.player2 == player, "Not in game");

    while i < game.caps_ids.len() {
        let cap: Cap = world.read_model(*game.caps_ids[i]);
        if cap.owner == player {
            pieces.append(cap.id);
        }
        i += 1;
    };

    pieces
}

pub fn get_piece_locations(ref game: Game, world: @WorldStorage) -> (Felt252Dict<Nullable<Cap>>, Felt252Dict<Nullable<u64>>) {
    let mut locations: Felt252Dict<Nullable<u64>> = Default::default();
    let mut keys: Felt252Dict<Nullable<Cap>> = Default::default();
    let mut i = 0;

    while i < game.caps_ids.len() {
        let cap: Cap = world.read_model(*game.caps_ids[i]);
        let index = cap.position.x * 7 + cap.position.y;
        locations.insert(index.into(), NullableTrait::new(cap.id));
        keys.insert(cap.id.into(), NullableTrait::new(cap));
        i += 1;
    };

    (locations, keys)
}

pub fn get_active_effects(ref game: Game, world: @WorldStorage) -> (Array<Effect>, Array<Effect>, Array<Effect>) {
    let mut start_of_turn_effects: Array<Effect> = ArrayTrait::new();
    let mut move_step_effects: Array<Effect> = ArrayTrait::new();
    let mut end_of_turn_effects: Array<Effect> = ArrayTrait::new();

    let mut i = 0;
    while i < game.effect_ids.len() {
        let effect: Effect = world.read_model((game.id, i).into());
        match effect.get_timing() {
            Timing::StartOfTurn => {
                start_of_turn_effects.append(effect);
            },
            Timing::MoveStep => {
                move_step_effects.append(effect);
            },
            Timing::EndOfTurn => {
                end_of_turn_effects.append(effect);
            },
            _ => {}
        }
        i += 1;
    };
    
    

    (start_of_turn_effects, move_step_effects, end_of_turn_effects)
}

pub fn get_active_effects_from_array(effects: @Array<Effect>) -> (Array<Effect>, Array<Effect>, Array<Effect>) {
    let mut start_of_turn_effects: Array<Effect> = ArrayTrait::new();
    let mut move_step_effects: Array<Effect> = ArrayTrait::new();
    let mut end_of_turn_effects: Array<Effect> = ArrayTrait::new();
    
    let mut i = 0;
    while i < effects.len() {
        let effect = *effects.at(i);
        match effect.get_timing() {
            Timing::StartOfTurn => {
                start_of_turn_effects.append(effect);
            },
            Timing::MoveStep => {
                move_step_effects.append(effect);
            },
            Timing::EndOfTurn => {
                end_of_turn_effects.append(effect);
            },
            _ => {}
        }
        i += 1;
    };

    (start_of_turn_effects, move_step_effects, end_of_turn_effects)
}

// Returns (game, extra_energy, stunned_pieces)
pub fn handle_start_of_turn_effects(start_of_turn_effects: @Array<Effect>) -> (u8, Array<u64>, Array<Effect>) {
    let mut i = 0;
    let mut extra_energy: u8 = 0;
    let mut stunned_pieces: Array<u64> = ArrayTrait::new();
    let mut new_effects: Array<Effect> = ArrayTrait::new();
    while i < start_of_turn_effects.len() {
        let mut effect = *start_of_turn_effects.at(i);
        effect.trigger();
        if effect.remaining_triggers > 0 {
            new_effects.append(effect);
        }
        match effect.effect_type {
            EffectType::ExtraEnergy(x) => {
                extra_energy += x;
            },
            EffectType::Stun(x) => {
                stunned_pieces.append(x.into());
            },
            _ => {}
        }
        i += 1;
    };
    (extra_energy, stunned_pieces, new_effects)
}

pub fn update_end_of_turn_effects(ref game: Game, ref end_of_turn_effects: Array<Effect>, ref world: WorldStorage) -> (Game, Array<Effect>) {
    let mut i = 0;
    let mut new_effects: Array<Effect> = ArrayTrait::new();
    while i < end_of_turn_effects.len() {
        let mut effect = *end_of_turn_effects.at(i);
        effect.trigger();
        if effect.remaining_triggers > 0 {
            new_effects.append(effect);
        }
        match effect.effect_type {
            EffectType::DOT(dmg) => {
                match effect.target {
                    EffectTarget::Cap(cap_id) => {
                        let mut cap: Cap = world.read_model(cap_id);
                        let (new_game, new_cap) = handle_damage(ref game, ref cap, dmg.into());
                        game = new_game;
                        world.write_model(@new_cap);
                    },
                    _ => {}
                }
            },
            EffectType::Heal(heal) => {
                match effect.target {
                    EffectTarget::Cap(cap_id) => {
                        let mut cap: Cap = world.read_model(cap_id);
                        if heal.into() > cap.dmg_taken {
                            cap.dmg_taken = 0;
                        }
                        else {
                            cap.dmg_taken -= heal.into();
                        }
                        world.write_model(@cap);
                    },
                    _ => {}
                }
            },
            _ => {}
        };
        i += 1;
    };
    (game.clone(), new_effects)
}

pub fn handle_damage(ref game: Game, ref target: Cap, amount: u64) -> (Game, Cap) {
    let cap_type = get_cap_type(target.cap_type).unwrap();

    let remaining_health = cap_type.base_health - target.dmg_taken;

    if target.shield_amt.into() > amount {
        target.shield_amt -= amount.try_into().unwrap();
    }
    else if amount > target.shield_amt.into() + remaining_health.into() {
        target.dmg_taken = cap_type.base_health;
        target.shield_amt = 0;
        game.remove_cap(target.id.try_into().unwrap());

    }
    else {
        target.dmg_taken += (amount - target.shield_amt.try_into().unwrap()).try_into().unwrap();
        target.shield_amt = 0;
    }

    return (game.clone(), target);

}

pub fn check_includes(array: @Array<u64>, id: u64) -> bool {
    let mut i = 0;
    let mut found = false;
    while i < array.len() {
        if *array.at(i) == id {
            found = true;
            break;
        }
        i += 1;
    };
    return found;
}

pub fn clone_dicts(game: @Game, ref locations: Felt252Dict<Nullable<u64>>, ref keys: Felt252Dict<Nullable<Cap>>) -> (Game, Felt252Dict<Nullable<Cap>>, Felt252Dict<Nullable<u64>>) {
    let mut new_locations: Felt252Dict<Nullable<u64>> = Default::default();
    let mut new_keys: Felt252Dict<Nullable<Cap>> = Default::default();

    let mut i = 0;
    while i < game.caps_ids.len() {
        let cap: Cap = keys.get((*game.caps_ids[i]).into()).deref();
        let index = cap.position.x * 7 + cap.position.y;
        new_locations.insert(index.into(), NullableTrait::new(cap.id));
        new_keys.insert(cap.id.into(), NullableTrait::new(cap));
        i += 1;
    };

    (game.clone(), new_keys, new_locations)
}