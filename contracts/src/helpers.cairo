use dojo::model::{ModelStorage};
use caps::models::game::{Game, GameTrait, Action, ActionType};
use caps::models::cap::{Cap, CapTrait, CapType, TargetType, TargetTypeTrait};
use caps::models::effect::{Effect, EffectTrait, EffectType, EffectTarget, Timing};
use caps::models::set::Set;
use caps::sets::set_zero::get_cap_type;
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
        if cap.owner == player {
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
        let index = cap.position.x * 7 + cap.position.y;
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
        let effect: Effect = world.read_model((game.id, i).into());
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
    effects: @Array<Effect>,
) -> (Array<Effect>, Array<Effect>, Array<Effect>) {
    let mut start_of_turn_effects: Array<Effect> = ArrayTrait::new();
    let mut move_step_effects: Array<Effect> = ArrayTrait::new();
    let mut end_of_turn_effects: Array<Effect> = ArrayTrait::new();

    let mut i = 0;
    while i < effects.len() {
        let effect = *effects.at(i);
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

// Returns (game, extra_energy, stunned_pieces)
pub fn handle_start_of_turn_effects(
    start_of_turn_effects: @Array<Effect>,
) -> (u8, Array<u64>, Array<Effect>) {
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
            EffectType::ExtraEnergy(x) => { extra_energy += x; },
            EffectType::Stun(x) => { stunned_pieces.append(x.into()); },
            _ => {},
        }
        i += 1;
    };
    (extra_energy, stunned_pieces, new_effects)
}

// This is the only function that writes to the world
// Probably should make a separate simulate fn that doesn't write
pub fn update_end_of_turn_effects(
    ref game: Game,
    ref end_of_turn_effects: Array<Effect>,
    ref locations: Felt252Dict<u64>,
    ref keys: Felt252Dict<Nullable<Cap>>,
) -> (Game, Array<Effect>, Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>) {
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
                        let mut cap: Cap = keys.get(cap_id.into()).deref();
                        let (new_game, new_cap) = handle_damage(ref game, ref cap, dmg.into());
                        game = new_game;
                        keys.insert(cap_id.into(), NullableTrait::new(new_cap));
                    },
                    _ => {},
                }
            },
            EffectType::Heal(heal) => {
                match effect.target {
                    EffectTarget::Cap(cap_id) => {
                        let mut cap: Cap = keys.get(cap_id.into()).deref();
                        if heal.into() > cap.dmg_taken {
                            cap.dmg_taken = 0;
                        } else {
                            cap.dmg_taken -= heal.into();
                        }
                        keys.insert(cap_id.into(), NullableTrait::new(cap));
                    },
                    _ => {},
                }
            },
            _ => {},
        };
        i += 1;
    };
    let (new_game, new_locations, new_keys) = clone_dicts(@game, ref locations, ref keys);
    (new_game, new_effects, new_locations, new_keys)
}

pub fn handle_damage(ref game: Game, ref target: Cap, amount: u64) -> (Game, Cap) {
    let cap_type = get_cap_type(target.cap_type).unwrap();

    let remaining_health = cap_type.base_health - target.dmg_taken;

    if target.shield_amt.into() > amount {
        target.shield_amt -= amount.try_into().unwrap();
    } else if amount > target.shield_amt.into() + remaining_health.into() {
        target.dmg_taken = cap_type.base_health;
        target.shield_amt = 0;
        game.remove_cap(target.id.try_into().unwrap());
    } else {
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

pub fn clone_dicts(
    game: @Game, ref locations: Felt252Dict<u64>, ref keys: Felt252Dict<Nullable<Cap>>,
) -> (Game, Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>) {
    let mut new_locations: Felt252Dict<u64> = Default::default();
    let mut new_keys: Felt252Dict<Nullable<Cap>> = Default::default();

    let mut i = 0;
    while i < game.caps_ids.len() {
        let cap: Cap = keys.get((*game.caps_ids[i]).into()).deref();
        let index = cap.position.x * 7 + cap.position.y;
        new_locations.insert(index.into(), cap.id);
        new_keys.insert(cap.id.into(), NullableTrait::new(cap));
        i += 1;
    };

    (game.clone(), new_locations, new_keys)
}

pub fn get_dicts_from_array(caps: @Array<Cap>) -> (Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>) {
    let mut locations: Felt252Dict<u64> = Default::default();
    let mut keys: Felt252Dict<Nullable<Cap>> = Default::default();

    let mut i = 0;
    while i < caps.len() {
        let cap: Cap = *caps.at(i);
        let index = cap.position.x * 7 + cap.position.y;
        locations.insert(index.into(), cap.id);
        keys.insert(cap.id.into(), NullableTrait::new(cap));
        i += 1;
    };

    (locations, keys)
}

pub fn process_actions(
    ref game: Game,
    ref turn: Array<Action>,
    ref locations: Felt252Dict<u64>,
    ref keys: Felt252Dict<Nullable<Cap>>,
    ref start_of_turn_effects: Array<Effect>,
    ref move_step_effects: Array<Effect>,
    ref end_of_turn_effects: Array<Effect>,
    ref set: Set,
    caller: ContractAddress,
) -> (
    Game, Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>, Array<Effect>, Array<Effect>, Array<Effect>,
) {
    //handle start of turn effects
    let (extra_energy, stunned_pieces, mut new_start_of_turn_effects) =
        handle_start_of_turn_effects(
        @start_of_turn_effects,
    );
    start_of_turn_effects = new_start_of_turn_effects;

    let mut energy: u8 = game.turn_count.try_into().unwrap() + 2 + extra_energy;

    let mut new_start_of_turn_effects: Array<Effect> = ArrayTrait::new();

    let mut i = 0;
    while i < turn.len() {
        let action = turn.at(i);
        let mut cap = keys.get((*action.cap_id).into()).deref();
        assert!(cap.owner == caller, "You are not the owner of this piece");
        assert!(!check_includes(@stunned_pieces, cap.id), "Piece is stunned");
        let cap_type: CapType = cap.get_cap_type(ref set);
        let mut new_effects: Array<Effect> = ArrayTrait::new();
        let mut new_move_step_effects: Array<Effect> = ArrayTrait::new();

        match action.action_type {
            ActionType::Move(dir) => {
                let mut move_discount: u8 = 0;
                let mut move_bonus: u8 = 0;
                for mut effect in move_step_effects {
                    match effect.effect_type {
                        EffectType::MoveDiscount(x) => {
                            move_discount += x;
                            effect.trigger();
                            if effect.remaining_triggers > 0 {
                                new_move_step_effects.append(effect);
                            }
                        },
                        EffectType::MoveBonus(x) => {
                            move_bonus += x;
                            effect.trigger();
                            if effect.remaining_triggers > 0 {
                                new_move_step_effects.append(effect);
                            }
                        },
                        _ => { new_move_step_effects.append(effect); },
                    }
                };
                move_step_effects = new_move_step_effects;
                let mut move_cost = cap_type.move_cost;
                if move_discount > cap_type.move_cost {
                    move_cost = 0;
                } else {
                    move_cost -= move_discount;
                }
                assert!(
                    move_cost <= energy,
                    "Not enough energy, move cost: {}, energy: {}",
                    move_cost,
                    energy,
                );
                energy -= move_cost;
                let new_location_index = cap.get_new_index_from_dir(*dir.x, *dir.y);
                let piece_at_location_id = locations.get(new_location_index.into());
                assert!(piece_at_location_id == 0, "There is a piece at the new location");
                let old_position_index = cap.position.x * 7 + cap.position.y;
                locations.insert(old_position_index.into(), 0);
                cap.move(cap_type, *dir.x, *dir.y, move_bonus);
                locations.insert((cap.position.x * 7 + cap.position.y).into(), cap.id);
                keys.insert(cap.id.into(), NullableTrait::new(cap));
            },
            ActionType::Attack(target) => {
                let mut attack_cost = cap_type.attack_cost;
                let mut attack_discount: u8 = 0;
                let mut attack_bonus: u8 = 0;

                for mut effect in move_step_effects {
                    match effect.effect_type {
                        EffectType::AttackDiscount(x) => {
                            attack_discount += x;
                            effect.trigger();
                            if effect.remaining_triggers > 0 {
                                new_move_step_effects.append(effect);
                            }
                        },
                        EffectType::AttackBonus(x) => {
                            attack_bonus += x;
                            effect.trigger();
                            if effect.remaining_triggers > 0 {
                                new_move_step_effects.append(effect);
                            }
                        },
                        _ => { new_move_step_effects.append(effect); },
                    }
                };
                move_step_effects = new_move_step_effects;
                if attack_discount > cap_type.attack_cost {
                    attack_cost = 0;
                } else {
                    attack_cost -= attack_discount;
                }

                assert!(attack_cost <= energy, "Not enough energy");
                energy -= attack_cost;
                let mut attack_dmg = cap_type.attack_dmg;
                attack_dmg += attack_bonus.into();

                let piece_at_location_id = locations.get((*target.x * 7 + *target.y).into());
                let mut piece_at_location: Cap = keys.get(piece_at_location_id.into()).deref();
                assert!(piece_at_location_id != 0, "There is no piece at the target location");
                assert!(piece_at_location.owner != caller, "You cannot attack your own piece");
                if (!cap.check_in_range(*target, @cap_type.attack_range)) {
                    panic!("Attack is not valid");
                }
                let (new_game, new_cap) = handle_damage(
                    ref game, ref piece_at_location, attack_dmg.try_into().unwrap(),
                );
                game = new_game;
                keys.insert(new_cap.id.into(), NullableTrait::new(new_cap));
            },
            ActionType::Ability(target) => {
                let mut cap_type: CapType = cap.get_cap_type(ref set);
                assert!(cap_type.ability_target != TargetType::None, "Ability should not be none");
                let (valid, new_game, new_locations, new_keys) = cap_type
                    .ability_target
                    .is_valid(@cap, ref cap_type, *target, ref game, ref locations, ref keys);
                game = new_game;
                keys = new_keys;
                locations = new_locations;
                assert!(valid, "Ability is not valid");
                let mut ability_cost = cap_type.ability_cost;
                let mut ability_discount = 0;
                let mut double_count: u8 = 0;

                for mut effect in move_step_effects {
                    match effect.effect_type {
                        EffectType::AbilityDiscount(x) => {
                            ability_discount += x;
                            effect.trigger();
                            if effect.remaining_triggers > 0 {
                                new_move_step_effects.append(effect);
                            }
                        },
                        EffectType::Double(x) => {
                            double_count += x;
                            effect.trigger();
                            if effect.remaining_triggers > 0 {
                                new_move_step_effects.append(effect);
                            }
                        },
                        _ => { new_move_step_effects.append(effect); },
                    }
                };
                move_step_effects = new_move_step_effects;
                if ability_discount > cap_type.ability_cost {
                    ability_cost = 0;
                } else {
                    ability_cost -= ability_discount;
                }

                assert!(ability_cost <= energy, "Not enough energy");
                energy -= ability_cost;

                let (mut game, mut created_effects, new_locations, new_keys) = cap
                    .use_ability(*target, ref game, @set, ref locations, ref keys);
                locations = new_locations;
                keys = new_keys;

                for effect in created_effects {
                    new_effects.append(effect);
                };

                while double_count > 0 {
                    let (valid, new_game, new_locations, new_keys) = cap_type
                        .ability_target
                        .is_valid(@cap, ref cap_type, *target, ref game, ref locations, ref keys);
                    game = new_game;
                    locations = new_locations;
                    keys = new_keys;
                    if valid {
                        let (mut game, new_double_effects, new_locations, new_keys) = cap
                            .use_ability(*target, ref game, @set, ref locations, ref keys);
                        locations = new_locations;
                        keys = new_keys;
                        for effect in new_double_effects {
                            new_effects.append(effect);
                        };
                        double_count -= 1;
                        game = new_game;
                    } else {
                        double_count = 0;
                    }
                }
            },
        };

        for effect in new_effects {
            match effect.get_timing() {
                Timing::StartOfTurn => { new_start_of_turn_effects.append(effect); },
                Timing::MoveStep => { move_step_effects.append(effect); },
                Timing::EndOfTurn => { end_of_turn_effects.append(effect); },
                _ => {},
            }
        };

        let (new_game, new_locations, new_keys) = clone_dicts(@game, ref locations, ref keys);
        game = new_game;
        keys = new_keys;
        locations = new_locations;
        i += 1;
    };

    let (new_game, new_locations, new_keys) = clone_dicts(@game, ref locations, ref keys);
    (
        new_game,
        new_locations,
        new_keys,
        new_start_of_turn_effects,
        move_step_effects.clone(),
        end_of_turn_effects.clone(),
    )
}
