use caps::helpers::{get_piece_locations, handle_damage, get_player_pieces};
use caps::models::effect::{Effect, EffectType, EffectTarget};
use caps::models::game::{Game, GameTrait, Vec2};
use caps::sets::set_zero::get_cap_type;

use dojo::world::WorldStorage;

use dojo::model::{ModelStorage};
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Cap {
    #[key]
    pub id: u64,
    pub owner: ContractAddress,
    pub position: Vec2,
    pub cap_type: u16,
    pub dmg_taken: u16,
    pub shield_amt: u16
}



#[generate_trait]
pub impl CapImpl of CapTrait {
    fn new(id: u64, owner: ContractAddress, position: Vec2, cap_type: u16) -> Cap {
        Cap { id, owner, position, cap_type, dmg_taken: 0, shield_amt: 0 }
    }

    fn get_new_index_from_dir(self: @Cap, direction: u8, amt: u8) -> felt252 {
        let mut new_position = *self.position;
        match direction {
            0 => if new_position.x + amt > 6 {
                panic!("Move out of bounds: would move to x: {} (start: {}, amt: {}) (get_new_index_from_dir)", new_position.x + amt, new_position.x, amt);
            } else {
                new_position.x += amt
            },
            1 => if amt > new_position.x {
                panic!("Move out of bounds: would move to x: -{} (start: {}, amt: {}) (get_new_index_from_dir)", amt - new_position.x, new_position.x, amt);
            } else {
                new_position.x -= amt
            },
            2 => if new_position.y + amt > 6 {
                panic!("Move out of bounds: would move to y: {} (start: {}, amt: {}) (get_new_index_from_dir)", new_position.y + amt, new_position.y, amt);
            } else {
                new_position.y += amt
            },
            3 => if amt > new_position.y {
                panic!("Move out of bounds: would move to y: -{} (start: {}, amt: {}) (get_new_index_from_dir)", amt - new_position.y, new_position.y, amt  );
            } else {
                new_position.y -= amt
            },
            _ => panic!("Invalid direction"),
        };
        (new_position.x * 7 + new_position.y).into()
    }

    fn move(ref self: Cap, cap_type: CapType, direction: u8, amount: u8, bonus_range: u8){
        let mut new_position = self.position;
        match direction {
            0 => {
                if new_position.x + amount > 6 {
                    panic!("Move out of bounds: would move to x: {} (start: {}, amt: {}) (Move)", new_position.x + amount, new_position.x, amount);
                }
                if amount > cap_type.move_range.x + bonus_range {
                    panic!("Move out of range");
                }
                new_position.x += amount;
            },
            1 => {
                if amount > new_position.x {
                    panic!("Move out of bounds: would move to x: -{} (start: {}, amt: {}) (Move)", amount - new_position.x, new_position.x, amount);
                }
                if amount > cap_type.move_range.x + bonus_range {
                    panic!("Move out of range");
                }
                new_position.x -= amount;
            },
            2 => {
                if new_position.y + amount > 6 {
                    panic!("Move out of bounds: would move to y: {} (start: {}, amt: {}) (Move)", new_position.y + amount, new_position.y, amount);
                }
                if amount > cap_type.move_range.y + bonus_range {
                    panic!("Move out of range");
                }
                new_position.y += amount;
            },
            3 => {
                if amount > new_position.y {
                    panic!("Move out of bounds: would move to y: -{} (start: {}, amt: {}) (Move)", amount - new_position.y, new_position.y, amount);
                }
                if amount > cap_type.move_range.y + bonus_range {
                    panic!("Move out of range");
                }
                new_position.y -= amount;
            },
            _ => (),
        };
        self.position = new_position;
    }

    fn check_in_range(self: @Cap, target: Vec2, range: @Array<Vec2>) -> bool {
        let mut valid = false;
        let mut i = 0;
        while i < range.len() {
            let to_check: Vec2 = *range[i];
            if target.x >= *self.position.x && target.y >= *self.position.y {
                if to_check.x + *self.position.x > 6 {
                }
                if to_check.y + *self.position.y > 6 {
                }
                if *self.position.x + to_check.x == target.x && *self.position.y + to_check.y == target.y {
                    valid = true;
                    break;
                }
                else {
                }
            }
            else if target.x <= *self.position.x && target.y <= *self.position.y {
                if to_check.x > *self.position.x {
                }
                if to_check.y > *self.position.y {
                }
                if *self.position.x - to_check.x == target.x && *self.position.y - to_check.y == target.y {
                    valid = true;
                    break;
                }
                else {
                }
            }
            else if target.x <= *self.position.x && target.y >= *self.position.y {
                if to_check.x > *self.position.x  {
                }
                if to_check.y + *self.position.y > 6 {
                }
                if *self.position.x - to_check.x == target.x && *self.position.y + to_check.y == target.y {
                    valid = true;
                    break;
                }
                else {
                }
            }
            else if target.x >= *self.position.x && target.y <= *self.position.y {
                if to_check.x + *self.position.x > 6 {
                }
                if to_check.y > *self.position.y {
                }
                if *self.position.x + to_check.x == target.x && *self.position.y - to_check.y == target.y {
                    valid = true;
                    break;
                }
                else {
                }
            }
            i += 1;
        };
        valid
    }

    fn use_ability(ref self: Cap, ref cap_type: CapType, target: Vec2, ref game: Game, ref world: WorldStorage) -> (Game, Array<Effect>) {
        let mut locations = get_piece_locations(ref game, @world);
        let mut new_effects: Array<Effect> = ArrayTrait::new();
        match self.cap_type {
            0 => {
                //none
            },
            1 => {
                //none
            },
            2 => {
                //none
            },
            3 => {
                //none
                },
            4 => {
                //Deal 5 damage to the target
                game = handle_damage(ref game, locations.get((target.x * 7 + target.y).into()), ref world, 4);
            },
            5 => {
                //Heal 5 damage
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                if cap_at_target.dmg_taken < 5 {
                    cap_at_target.dmg_taken = 0;
                }
                cap_at_target.dmg_taken -= 5;
                world.write_model(@cap_at_target);
            },
            6 => {
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                cap_at_target.shield_amt += 5;
                world.write_model(@cap_at_target);
            },
            7 => {
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::AbilityDiscount(1),
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 2,
                };
                new_effects.append(effect);
                game.effect_ids.append(effect.effect_id);
            },
            8 => {
                let effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::AttackBonus(self.dmg_taken.try_into().unwrap()),
                    target: EffectTarget::Cap(self.id),
                    remaining_triggers: 2,
                };
                new_effects.append(effect);
                game.effect_ids.append(effect.effect_id);
            },
            9 => {
                game = handle_damage(ref game, locations.get((target.x * 7 + target.y).into()), ref world, self.dmg_taken.into());
                self.dmg_taken = 0;
                world.write_model(@self);
            },
            10 => {
                
                
                let cap_type = get_cap_type(self.cap_type);
                let new_effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::AttackDiscount(cap_type.unwrap().attack_cost.try_into().unwrap()),
                    target: EffectTarget::Cap(self.id),
                    remaining_triggers: self.shield_amt.try_into().unwrap(),
                };
                new_effects.append(new_effect);
                game.effect_ids.append(new_effect.effect_id);
                                        
            },
            11 => {
                
                //none
                let mut energy_effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::ExtraEnergy(2),
                    target: EffectTarget::Cap(self.id),
                    remaining_triggers: 2,
                };
                new_effects.append(energy_effect);
                game.effect_ids.append(energy_effect.effect_id);
                self.shield_amt += 2;
                world.write_model(@self);
            },
            12 => {
                //none
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                let target_cap_type = get_cap_type(cap_at_target.cap_type);

                if target_cap_type.unwrap().base_health - cap_at_target.dmg_taken == 1 {
                    game.remove_cap(cap_at_target_id);
                    world.erase_model(@cap_at_target);
                }
                else {
                    cap_at_target.dmg_taken += 1;
                    let effect = Effect {
                        game_id: game.id,
                        effect_id: game.effect_ids.len().into(),
                        effect_type: EffectType::DamageBuff(3),
                        target: EffectTarget::Cap(cap_at_target_id),
                        remaining_triggers: 2,
                    };
                    new_effects.append(effect);
                    game.effect_ids.append(effect.effect_id);
                    world.write_model(@cap_at_target);
                }
            },
            13 => {
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
            },
            14 => {
                let mut i = 0;
                while i < game.effect_ids.len() {
                    let effect: Effect = world.read_model((game.id, i).into());
                    match effect.effect_type {
                        EffectType::Shield(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == self.id {
                                        let new_effect = Effect {
                                            game_id: game.id,
                                            effect_id: game.effect_ids.len().into(),
                                            effect_type: EffectType::MoveDiscount(x.try_into().unwrap()),
                                            target: effect.target,
                                            remaining_triggers: x + 1,
                                        };
                                        new_effects.append(new_effect);
                                        game.effect_ids.append(new_effect.effect_id);
                                    }
                                },
                                _ => (),
                            }
                        },
                        _ => (),
                    }
                    i += 1;
                };
            },
            15 => {
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::Double(1),
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 2,
                };
                new_effects.append(effect);
                game.effect_ids.append(effect.effect_id);
            },
            16 => {
                //none
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::DOT(1),
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 4,
                };  
                new_effects.append(effect);
                game.effect_ids.append(effect.effect_id);
            },
            17 => {
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::Heal(2),
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 4,
                };
                new_effects.append(effect);
                game.effect_ids.append(effect.effect_id);
            },
            18 => {
                self.shield_amt *= 2;
                world.write_model(@self);
            },
            19 => {
                 //none
                let mut i = 0;
                while i < game.effect_ids.len() {
                    let effect: Effect = world.read_model((game.id, i).into());
                    match effect.effect_type {
                        EffectType::ExtraEnergy(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == self.id {
                                        let new_effect = Effect {
                                            game_id: game.id,
                                            effect_id: game.effect_ids.len().into(),
                                            effect_type: EffectType::AttackBonus(x.try_into().unwrap()),
                                            target: effect.target,
                                            remaining_triggers: 2,
                                        };
                                        new_effects.append(new_effect);
                                        game.effect_ids.append(new_effect.effect_id);
                                        break;
                                    }
                                },
                                _ => (),
                            }
                        },
                        _ => (),
                    }
                    i += 1;
                };
            },
            20 => {
                let self_cap_type = get_cap_type(self.cap_type).unwrap();
                let clone = self_cap_type.clone();
                let self_health = if clone.base_health > self.dmg_taken {
                    clone.base_health - self.dmg_taken
                } else {
                    0
                };
                
                if self_health < 5 {
                    panic!("Not enough health, ability would kill self");
                }
                game = handle_damage(ref game, locations.get((target.x * 7 + target.y).into()), ref world, 7);
                game = handle_damage(ref game, self.id, ref world, 4);
            },
            21 => {
                game = handle_damage(ref game, locations.get((target.x * 7 + target.y).into()), ref world, 9);
            },
            22 => {
                //none
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                let cap_at_target_type = get_cap_type(cap_at_target.cap_type);
                
                let mut ally_shield = cap_at_target.shield_amt.try_into().unwrap();
               
                self.shield_amt += ally_shield;
                world.write_model(@self);
            },
            23 => {
                //none
                let player_pieces = get_player_pieces(game.id, game.player1, @world);

                let mut i = 0;
                let mut extra_energy = 0;
                while i < game.effect_ids.len() {
                    let effect: Effect = world.read_model((game.id, i).into());
                    match effect.effect_type {
                        EffectType::ExtraEnergy(x) => {
                            extra_energy += x.into();
                        },
                        _ => (),
                    }
                    i += 1;
                };
            //    game = handle_damage(ref game, self.id, ref world, 2 + extra_energy);
                
            },
            _ => panic!("Not yet implemented"),
        }

        (game.clone(), new_effects)
    }

}



//This is never getting stored. It's just a model to generate the bindings
#[derive(Drop, Serde, Debug, Clone, Introspect)]
#[dojo::model]
pub struct CapType {
    #[key]
    pub id: u16,
    pub name: ByteArray,
    pub description: ByteArray,
    pub move_cost: u8,
    pub attack_cost: u8,
    // Attack range is the squares relative to the cap's position that can be attacked
    pub attack_range: Array<Vec2>,
    pub ability_range: Array<Vec2>,
    pub ability_description: ByteArray,
    // Move range is the x range, y range
    pub move_range: Vec2,
    pub attack_dmg: u16,
    pub base_health: u16,
    pub ability_target: TargetType,
    pub ability_cost: u8,
}






#[derive(Copy, Drop, Serde, Debug, PartialEq, Introspect)]
pub enum TargetType {
    None,
    SelfCap,
    TeamCap,
    OpponentCap,
    AnyCap,
    AnySquare,
}

#[generate_trait]
pub impl TargetTypeImpl of TargetTypeTrait {
    fn is_valid(self: @TargetType, cap: @Cap, ref cap_type: CapType, target: Vec2, ref game: Game, world: @WorldStorage) -> (bool, Game) {
        match *self {
            TargetType::None => (false, game.clone()),
            TargetType::SelfCap => {
                (true, game.clone())
            },
            TargetType::TeamCap => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                let in_range = cap.check_in_range(target, @cap_type.ability_range);
                assert!(in_range, "Target not in range");
                let mut locations = get_piece_locations(ref game, world);
                let at_location_index = locations.get((target.x * 7 + target.y).into());
                assert!(at_location_index != 0, "No cap at location");
                let at_location: Cap = world.read_model(at_location_index);
                //Must be player
                assert!(at_location.owner == *cap.owner, "Cap is not owned by player");
                if in_range && at_location.owner == *cap.owner {
                    return (true, game.clone());
                }
                (false, game.clone())
            },
            TargetType::OpponentCap => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                let in_range = cap.check_in_range(target, @cap_type.ability_range);
                assert!(in_range, "Target not in range");
                let mut locations = get_piece_locations(ref game, world);
                let at_location_index = locations.get((target.x * 7 + target.y).into());
                assert!(at_location_index != 0, "No cap at location");
                let at_location: Cap = world.read_model(at_location_index);
                assert!(*cap.owner != starknet::contract_address_const::<0x0>(), "Cap owner 0?");
                assert!(at_location.owner != *cap.owner, "Cap is owned by player");
                //Must be opponent
                if in_range && at_location.owner != *cap.owner {
                    return (true, game.clone());
                }
                (false, game.clone())
            },
            TargetType::AnyCap => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                let in_range = cap.check_in_range(target, @cap_type.ability_range);
                assert!(in_range, "Target not in range");
                let mut locations = get_piece_locations(ref game, world);
                let at_location_index = locations.get((target.x * 7 + target.y).into());
                if at_location_index != 0 && in_range {
                    return (true, game.clone());
                }
                (false, game.clone())
            },
            TargetType::AnySquare => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                (cap.check_in_range(target, @cap_type.ability_range), game.clone())
            },
        }
    }
}
