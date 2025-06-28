use super::effect::{Effect};
use super::game::{Game, Vec2};

use core::dict::Felt252Dict;
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Debug)]
pub struct Cap {
    pub id: u64,
    pub owner: ContractAddress,
    pub position: Vec2,
    pub set_id: u64,
    pub cap_type: u16,
    pub dmg_taken: u16,
    pub shield_amt: u16
}



#[generate_trait]
pub impl CapImpl of CapTrait {
    fn new(id: u64, owner: ContractAddress, position: Vec2, set_id: u64, cap_type: u16) -> Cap {
        Cap { id, owner, position, set_id, cap_type, dmg_taken: 0, shield_amt: 0 }
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

    fn use_ability(ref self: Cap, target: Vec2, ref game: Game, set: @Set, locations: Felt252Dict<Nullable<Cap>>) -> (Game, Array<Effect>, Felt252Dict<Nullable<Cap>>) {
        let mut cap_type = get_cap_type(self.cap_type);
        activate_ability(self, cap_type, target, game, locations)
    }

}



//This is never getting stored. It's just a model to generate the bindings
#[derive(Drop, Serde, Debug, Clone, Introspect)]
pub struct CapType {
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
    fn is_valid(self: @TargetType, cap: @Cap, ref cap_type: CapType, target: Vec2, ref game: Game, locations: Felt252Dict<Nullable<Cap>>) -> (bool, Game) {
        match *self {
            TargetType::None => (false, game.clone()),
            TargetType::SelfCap => {
                (true, game.clone())
            },
            TargetType::TeamCap => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                let in_range = cap.check_in_range(target, @cap_type.ability_range);
                assert!(in_range, "Target not in range");
                let at_location = locations.get((target.x * 7 + target.y).into()).deref();
                assert!(at_location.id != 0, "No cap at location");
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
                let at_location = locations.get((target.x * 7 + target.y).into()).deref();
                assert!(at_location.id != 0, "No cap at location");
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
                let at_location = locations.get((target.x * 7 + target.y).into()).deref();
                if at_location.id != 0 && in_range {
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



fn activate_ability(ref cap: Cap, ref cap_type: CapType, target: Vec2, ref game: Game, ref locations: Felt252Dict<Nullable<Cap>>) -> (Game, Array<Effect>, Felt252Dict<Nullable<Cap>>) {
    let mut new_effects: Array<Effect> = ArrayTrait::new();
    let mut new_locations: Felt252Dict<Nullable<Cap>> = Default::default();
    match cap_type.id {
        0 => {
            // "None"
        },
        1 => {
            // "None"
        },
        2 => {
            // "None"
        },
        3 => {
            // "None"
            },
        4 => {
            // "Deal 4 damage to an enemy"
            let mut cap = locations.get((target.x * 7 + target.y).into()).deref();
            let (new_game, new_cap) = handle_damage(ref game, ref cap, 4);
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(new_cap));
            game = new_game;
        },
        5 => {
            // "Heal 5 damage from an ally"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            if cap_at_target.dmg_taken < 5 {
                cap_at_target.dmg_taken = 0;
            }
            else {
                cap_at_target.dmg_taken -= 5;
            }
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(cap_at_target));
        },
        6 => {
            // "Shield an ally for 5"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            cap_at_target.shield_amt += 5;
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(cap_at_target));
        },
        7 => {
            // "Target unit's next ability use costs 1 less energy"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::AbilityDiscount(1),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 1,
            };
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        8 => {
            // "Next attack deals 1 more damage for each damage this unit has taken"
            let effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::AttackBonus(cap.dmg_taken.try_into().unwrap()),
                target: EffectTarget::Cap(cap.id),
                remaining_triggers: 1,
            };
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        9 => {
            // "Fully heal this unit, then damage an enemy unit equal to the amount healed"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let (new_game, new_cap) = handle_damage(ref game, ref cap_at_target, cap.dmg_taken.into());
            cap_at_target = new_cap;
            game = new_game;
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(cap_at_target));
        },
        10 => {
            // "Gain free attacks equal to the strength of this cards shield"
            let cap_type = get_cap_type(cap.cap_type);
            let new_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::AttackDiscount(cap_type.unwrap().attack_cost.try_into().unwrap()),
                target: EffectTarget::Cap(cap.id),
                remaining_triggers: cap.shield_amt.try_into().unwrap(),
            };
            new_effects.append(new_effect);
            game.effect_ids.append(new_effect.effect_id);
                                    
        },
        11 => {
            // "Next turn gain 2 energy. This card becomes stunned next turn and recieves a 2 health shield"
            let mut energy_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::ExtraEnergy(2),
                target: EffectTarget::Cap(cap.id),
                remaining_triggers: 2,
            };
            new_effects.append(energy_effect);
            game.effect_ids.append(energy_effect.effect_id);
            cap.shield_amt += 2;
            locations.insert(cap.id.into(), NullableTrait::new(cap));
        },
        12 => {
            // "Deal 1 damage to an ally to make its next attack deal 3 more damage"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let target_cap_type = get_cap_type(cap_at_target.cap_type);

            if target_cap_type.unwrap().base_health - cap_at_target.dmg_taken == 1 {
                game.remove_cap(cap_at_target.id.try_into().unwrap());
                locations.insert((target.x * 7 + target.y).into(), Default::default());
            }
            else {
                cap_at_target.dmg_taken += 1;
                let effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::DamageBuff(3),
                    target: EffectTarget::Cap(cap_at_target.id),
                    remaining_triggers: 1,
                };
                new_effects.append(effect);
                game.effect_ids.append(effect.effect_id);
                locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(cap_at_target));
            }
        },
        13 => {
            // "Stun a target enemy unit"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let stun_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::Stun(1),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 1,
            };
            new_effects.append(stun_effect);
            game.effect_ids.append(stun_effect.effect_id);
        },
        14 => {
            // "Target unit gains move range equal to its shield health"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let new_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::MoveDiscount(cap_at_target.shield_amt.try_into().unwrap()),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 1,
            };
            new_effects.append(new_effect);
                                
        },
        15 => {
            // "Repeat the effect of the ally's next ability (if possible)"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let mut effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::Double(1),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 2,
            };
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        16 => {
            // "Inflict target with burn that deals 3 damage each turn for 3 turns"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let mut effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::DOT(1),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 3,
            };  
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        17 => {
            // "Target unit heals 2 health per turn at the end of the next 3 turns"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let mut effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::Heal(2),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 3,
            };
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        18 => {
            // "Double the strength of this unit's shield"
            cap.shield_amt *= 2;
            locations.insert(cap.id.into(), NullableTrait::new(cap));
        },
        19 => {
            // "Next attack deals 1 more damage for each extra energy you started this turn with"
            //todo
        },
        20 => {
            // "Deal 4 damage to self and 7 damage to an enemy"
            let self_cap_type = get_cap_type(cap.cap_type).unwrap();
            let clone = self_cap_type.clone();
            let self_health = if clone.base_health > cap.dmg_taken {
                clone.base_health - cap.dmg_taken
            } else {
                0
            };
            
            if self_health < 5 {
                panic!("Not enough health, ability would kill self");
            }
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let (new_game, new_cap) = handle_damage(ref game, ref cap_at_target, 7);
            game = new_game;
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(new_cap));
            let (new_game, new_cap) = handle_damage(ref game, ref cap, 4);
            game = new_game;
            locations.insert(cap.id.into(), NullableTrait::new(new_cap));
        },
        21 => {
            // "Deal 8 damage to an enemy, but stun this unit next turn"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let (new_game, new_cap) = handle_damage(ref game, ref cap_at_target, 9);
            game = new_game;
            let stun_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::Stun(1),
                target: EffectTarget::Cap(cap.id),
                remaining_triggers: 1,
            };
            new_effects.append(stun_effect);
            game.effect_ids.append(stun_effect.effect_id);
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(new_cap));
        },
        22 => {
            // "Gain shield equal to target unit's shield"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let mut ally_shield = cap_at_target.shield_amt.try_into().unwrap();
           
            cap.shield_amt += ally_shield;
            locations.insert(cap.id.into(), NullableTrait::new(cap));
        },
        23 => {
            // "Heal all allies for 2 health"
            //todo
        //    game = handle_damage(ref game, self.id, ref world, 2 + extra_energy);
            
        },
        _ => panic!("Not yet implemented"),
    }



    (game.clone(), new_effects, locations)
}


pub fn get_cap_type(cap_type: u16) -> Option<CapType> {
    let res = match cap_type {
        0 => Option::Some(CapType {
            id: 0,
            name: "Red Tower",
            description: "Red Tower",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "None",
            move_range: Vec2 { x: 1, y: 1 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::None,
            ability_cost: 0,
        }),
        1 => Option::Some(CapType {
            id: 1,
            name: "Blue Tower",
            description: "Blue Tower",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "None",
            move_range: Vec2 { x: 1, y: 1 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::None,
            ability_cost: 0,
        }),
        2 => Option::Some(CapType {
            id: 2,
            name: "Yellow Tower",
            description: "Yellow Tower",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "None",
            move_range: Vec2 { x: 1, y: 1 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::None,
            ability_cost: 0,
        }),
        3 => Option::Some(CapType {
            id: 3,
            name: "Green Tower",
            description: "Green Tower",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "None",
            move_range: Vec2 { x: 1, y: 1 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::None,
            ability_cost: 0,
        }),
        4 => Option::Some(CapType {
            id: 4,
            name: "Red Basic",
            description: "Cap 3",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 1 } , Vec2 { x: 1, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 1 }],
            ability_description: "Deal 4 damage to an enemy",
            move_range: Vec2 { x: 1, y: 2 },
            attack_dmg: 2,
            base_health: 8,
            ability_target: TargetType::OpponentCap,
            ability_cost: 2,
        }),
        5 => Option::Some(CapType {
            id: 5,
            name: "Blue Basic",
            description: "Cap 4",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Heal 5 damage from an ally",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 7,
            ability_target: TargetType::TeamCap,
            ability_cost: 3,
        }),
        6 => Option::Some(CapType {
            id: 6,
            name: "Yellow Basic",
            description: "Cap 5",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 1, y: 1 }, Vec2 { x: 2, y: 2 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Shield an ally for 5",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 9,
            ability_target: TargetType::TeamCap,
            ability_cost: 3,
        }),
        7 => Option::Some(CapType {
            id: 7,
            name: "Green Basic",
            description: "Cap 6",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 1, y: 1 }, Vec2 { x: 2, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "Target unit's next ability use costs 1 less energy",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::TeamCap,
            ability_cost: 2,

        }),
        8 => Option::Some(CapType {
            id: 8,
            name: "Red Elite",
            description: "Cap 8",
            move_cost: 2,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_range: array![],
            ability_description: "Next attack deals 1 more damage for each damage this unit has taken",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 5,
            base_health: 14,
            ability_target: TargetType::SelfCap,
            ability_cost: 4,
        }),
        9 => Option::Some(CapType {
            id: 9,
            name: "Blue Elite",
            description: "Cap 9",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Fully heal this unit, then damage an enemy unit equal to the amount healed",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 11,
            ability_target: TargetType::OpponentCap,
            ability_cost: 2,
        }),
        10 => Option::Some(CapType {
            id: 10,
            name: "Yellow Elite",
            description: "Cap 10",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 {x: 1, y: 2}, Vec2 {x: 2, y: 1}],
            ability_range: array![],
            ability_description: "Gain free attacks equal to the strength of this cards shield",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 2,
            base_health: 13,
            ability_target: TargetType::SelfCap,
            ability_cost: 5,
        }),
        11 => Option::Some(CapType {
            id: 11,
            name: "Green Elite",
            description: "Cap 11",
            move_cost: 3,
            attack_cost: 5,
            attack_range: array![Vec2 { x: 1, y: 0}, Vec2 {x: 2, y: 0}, Vec2 {x: 1, y: 1}],
            ability_range: array![],
            ability_description: "Next turn gain 2 energy. This card becomes stunned next turn and recieves a 2 health shield",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 8,
            base_health: 16,
            ability_target: TargetType::SelfCap,
            ability_cost: 3,
        }),
        12 => Option::Some(CapType {
            id: 12,
            name: "Red Mage",
            description: "Red Mage",
            move_cost: 2,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 {x:3, y:3}, Vec2 {x: 2, y: 2}],
            ability_description: "Deal 1 damage to an ally to make its next attack deal 3 more damage",
            move_range: Vec2 { x: 3, y: 2 },
            attack_dmg: 1,
            base_health: 12,
            ability_target: TargetType::TeamCap,
            ability_cost: 1,
        }),
        13 => Option::Some(CapType {
            id: 13,
            name: "Blue Mage",
            description: "Blue Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 {x: 2, y: 0}],
            ability_description: "Stun a target enemy unit",
            move_range: Vec2 { x: 2, y: 1 },
            attack_dmg: 1,
            base_health: 13,
            ability_target: TargetType::OpponentCap,
            ability_cost: 3,
        }),
        14 => Option::Some(CapType {
            id: 14,
            name: "Yellow Mage",
            description: "Yellow Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 {x: 2, y: 0},  Vec2 {x: 0, y: 2}],
            ability_description: "Target unit gains move range equal to its shield health",
            move_range: Vec2 { x: 3, y: 2 },
            attack_dmg: 1,
            base_health: 10,
                ability_target: TargetType::TeamCap,
            ability_cost: 2,
        }),
        15 => Option::Some(CapType {
            id: 15,
            name: "Green Mage",
            description: "Green Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }],
            ability_description: "Repeat the effect of the ally's next ability (if possible)",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::SelfCap,
            ability_cost: 0,
        }),
        16 => Option::Some(CapType {
            id: 16,
            name: "Red Dragon",
            description: "Cap 3",
            move_cost: 5,
            attack_cost: 6,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 {x: 1, y: 1}, Vec2 {x: 2, y: 2}, Vec2 {x: 2, y: 0}],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_description: "Inflict target with burn that deals 3 damage each turn for 3 turns",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 9,
            base_health: 20,
            ability_target: TargetType::OpponentCap,
            ability_cost: 5,
        }),
        17 => Option::Some(CapType {
            id: 17,
            name: "Blue Mermaid",
            description: "Blue Mermaid",
            move_cost: 3,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Target unit heals 2 health per turn at the end of the next 3 turns",
            move_range: Vec2 { x: 2, y: 1 },
            attack_dmg: 6,
            base_health: 15,
            ability_target: TargetType::TeamCap,
            ability_cost: 3,
        }),
        18 => Option::Some(CapType {
            id: 18,
            name: "Yellow Trickster",
            description: "Yellow Trickster",
            move_cost: 2,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![],
            ability_description: "Double the strength of this unit's shield",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 12,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        19 => Option::Some(CapType {
            id: 19,
            name: "Green Tank",
            description: "Green Tank",
            move_cost: 6,
            attack_cost: 7,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Next attack deals 1 more damage for each extra energy you started this turn with",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 13,
            base_health: 25,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        20 => Option::Some(CapType {
            id: 20,
            name: "Red Knight",
            description: "Red Knight",
            move_cost: 2,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 {x: 1, y: 1}],
            ability_description: "Deal 4 damage to self and 7 damage to an enemy",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 6,
            base_health: 16,
            ability_target: TargetType::OpponentCap,
            ability_cost: 4,
        }),
        21 => Option::Some(CapType {
            id: 21,
            name: "Blue Elite",
            description: "Cap 9",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Deal 8 damage to an enemy, but stun this unit next turn",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 11,
            ability_target: TargetType::OpponentCap,
            ability_cost: 2,
        }),
        22 => Option::Some(CapType {
            id: 22,
            name: "Yellow Elite",
            description: "Cap 10",
            move_cost: 3,
            attack_cost: 5,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Gain shield equal to target unit's shield",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 8,
            base_health: 26,
            ability_target: TargetType::TeamCap,
            ability_cost: 4,
        }),
        23 => Option::Some(CapType {
            id: 23,
            name: "Green Elite",
            description: "Cap 11",
            move_cost: 3,
            attack_cost: 5,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Heal all allies for 2 health, plus 1 health per extra energy you started this turn with",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 10,
            base_health: 26,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        _ => Option::None,
    };
    res
}
