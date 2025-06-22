
use dojo::model::{ModelStorage};
use caps::models::{Game, Cap, GameTrait, EffectType, EffectTrait, TargetType, TargetTypeTrait, EffectTarget, Timing };
use starknet::ContractAddress;
use dojo::world::WorldStorage;
use core::dict::Felt252Dict;
use caps::models::{Effect, handle_damage};

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

pub fn get_piece_locations(game_id: u64, world: @WorldStorage) -> Felt252Dict<u64> {
    let mut game: Game = world.read_model(game_id);
    let mut locations: Felt252Dict<u64> = Default::default();

    let mut i = 0;

    while i < game.caps_ids.len() {
        let cap: Cap = world.read_model(*game.caps_ids[i]);
        let index = cap.position.x * 7 + cap.position.y;
        locations.insert(index.into(), cap.id);
        i += 1;
    };

    locations
}

pub fn get_active_effects(game_id: u64, world: @WorldStorage) -> (Array<Effect>, Array<Effect>, Array<Effect>) {
    let mut game: Game = world.read_model(game_id);
    let mut start_of_turn_effects: Array<Effect> = ArrayTrait::new();
    let mut move_step_effects: Array<Effect> = ArrayTrait::new();
    let mut end_of_turn_effects: Array<Effect> = ArrayTrait::new();

    let mut i = 0;
    while i< game.active_start_of_turn_effects.len() {
        let effect: Effect = world.read_model((game_id, *game.active_start_of_turn_effects[i]).into());
        start_of_turn_effects.append(effect);
        i += 1;
    };

    i = 0;
    while i< game.active_move_step_effects.len() {
        let effect: Effect = world.read_model((game_id, *game.active_move_step_effects[i]).into());
        move_step_effects.append(effect);
        i += 1;
    };

    i = 0;
    while i< game.active_end_of_turn_effects.len() {
        let effect: Effect = world.read_model((game_id, *game.active_end_of_turn_effects[i]).into());
        end_of_turn_effects.append(effect);
        i += 1;
    };

    (start_of_turn_effects, move_step_effects, end_of_turn_effects)
}

pub fn update_start_of_turn_effects(game_id: u64, ref world: WorldStorage) {
    let mut game: Game = world.read_model(game_id);
    let mut i = 0;
    while i < game.effect_counter {
        let mut effect: Effect = world.read_model((game_id, i).into());
        effect.remaining_triggers -= 1;
        if effect.remaining_triggers == 0 {
            game.remove_effect(effect);
            world.erase_model(@effect);
            world.write_model(@game);
        }
        else {
            world.write_model(@effect);
        }
        i += 1;
    }
}

pub fn update_move_step_effects(game_id: u64, ref world: WorldStorage, untriggered_effects: Array<u64>) {
    let mut game: Game = world.read_model(game_id);
    let mut i = 0;
    let mut new_ids: Array<u64> = ArrayTrait::new();
    while i < game.effect_counter {
        let effect_id = i;
        let mut j = 0;
        let mut untriggered = false;
        let mut effect: Effect = world.read_model((game_id, effect_id).into());
        if effect.get_timing() != Timing::MoveStep {
            continue;
        }
        while j < untriggered_effects.len() {
            if effect_id == *untriggered_effects.at(j) {
                new_ids.append(effect_id);
                untriggered = true;
                break;
            }
            j += 1;
        };
        if !untriggered {
            effect.remaining_triggers -= 1;
            if effect.remaining_triggers == 0 {
                game.remove_effect(effect);
                world.erase_model(@effect);
            }
            else {
                new_ids.append(effect_id);
                world.write_model(@effect);
            }
        }
        i+=1;
    };
    game.active_move_step_effects = new_ids;
    world.write_model(@game);
}

pub fn update_end_of_turn_effects(game_id: u64, ref world: WorldStorage) {
    let mut game: Game = world.read_model(game_id);
    let mut i = 0;
    let mut new_ids: Array<u64> = ArrayTrait::new();
    while i < game.effect_counter {
        let effect_id = i;
        let mut effect: Effect = world.read_model((game_id, effect_id).into());
        if effect.remaining_triggers == 0 {
            continue;
        }
        effect.remaining_triggers -= 1;
        match effect.effect_type {
            EffectType::DOT(dmg) => {
                match effect.target {
                    EffectTarget::Cap(cap_id) => {
                        let cap: Cap = world.read_model(cap_id);
                        handle_damage(game_id, cap_id, ref world, dmg.into());
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
                        cap.dmg_taken -= heal.into();
                        world.write_model(@cap);
                    },
                    _ => {}
                }
            },
            _ => {}
        };
        match effect.get_timing() {
            Timing::EndOfTurn => {
                effect.remaining_triggers -= 1;
                if effect.remaining_triggers == 0 {
                    world.erase_model(@effect);
                }
                else {
                    new_ids.append(effect_id);
                    world.write_model(@effect);
                }
            }, 
            _ => {}
        }
        i += 1;
    };
    game.active_end_of_turn_effects = new_ids;
    world.write_model(@game);
}