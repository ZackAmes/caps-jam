
use dojo::model::{ModelStorage};
use caps::models::game::{Game, GameTrait, Vec2};
use caps::models::cap::{Cap, CapTrait};
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

pub fn get_piece_locations(ref game: Game, world: @WorldStorage) -> Felt252Dict<u64> {
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

pub fn update_start_of_turn_effects(ref game: Game, ref world: WorldStorage) -> Game {
    let mut i = 0;
    let mut new_ids: Array<u64> = ArrayTrait::new();
    while i < game.active_start_of_turn_effects.len() {
        let mut effect: Effect = world.read_model((game.id, i).into());
        if effect.remaining_triggers == 1 {
            world.erase_model(@effect);
        }
        else if effect.remaining_triggers > 1 {
            effect.remaining_triggers -= 1;
            new_ids.append(effect.effect_id);
            world.write_model(@effect);
        }
        i += 1;
    };
    game.active_start_of_turn_effects = new_ids;
    game.clone()
}

pub fn update_end_of_turn_effects(ref game: Game, ref world: WorldStorage) -> Game {
    let mut i = 0;
    let mut new_ids: Array<u64> = ArrayTrait::new();
    while i < game.active_end_of_turn_effects.len().into() {
        let effect_id = i;
        let mut effect: Effect = world.read_model((game.id, effect_id).into());
        if effect.remaining_triggers == 1 {
            world.erase_model(@effect);
            continue;
        }
        else {
            effect.remaining_triggers -= 1;
            new_ids.append(effect_id);
            world.write_model(@effect);
        }
        match effect.effect_type {
            EffectType::DOT(dmg) => {
                match effect.target {
                    EffectTarget::Cap(cap_id) => {
                        game = handle_damage(ref game, cap_id, ref world, dmg.into());
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
                
                if effect.remaining_triggers == 1 {
                    world.erase_model(@effect);
                }
                else {
                    effect.remaining_triggers -= 1;
                    new_ids.append(effect_id);
                    world.write_model(@effect);
                }
            }, 
            _ => {}
        }
        i += 1;
    };
    game.active_end_of_turn_effects = new_ids;
    game.clone()
}

pub fn handle_damage(ref game: Game, target_id: u64, ref world: WorldStorage, amount: u64) -> Game {
    let mut target: Cap = world.read_model(target_id);
    let cap_type = get_cap_type(target.cap_type);

    let remaining_health = cap_type.unwrap().base_health - target.dmg_taken;


    let mut i = 0;
    let mut shield_amount = 0;
    while i < game.active_move_step_effects.len() {
        let mut effect: Effect = world.read_model((game.id, *game.active_move_step_effects.at(i)).into());
        match effect.effect_type {
            EffectType::Shield(val) => {
                match effect.target {
                    EffectTarget::Cap(effect_target_id) => {
                        if effect_target_id == target_id {
                            let mut new_val = 0;
                            shield_amount = val.into();
                            if val.into() > amount {
                                new_val = val.into() - amount;
                                effect.effect_type = EffectType::Shield(new_val.try_into().unwrap());
                                
                                world.write_model(@effect);
                            }
                            else {
                                game.remove_effect(effect);
                                world.erase_model(@effect);
                            }
                        }
                        
                    },
                    _ => {}
                }
            },
            _ => {}
        }
        i += 1;
    };

    if shield_amount > amount {

    }
    else if amount > shield_amount.into() + remaining_health.into() {
        game.remove_cap(target_id.try_into().unwrap());
        world.erase_model(@target);

    }
    else {
        target.dmg_taken += (amount - shield_amount.into()).try_into().unwrap();
        world.write_model(@target);
    }

    return game.clone();

}