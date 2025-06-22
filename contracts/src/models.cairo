use starknet::{ContractAddress};
use dojo::model::{ModelStorage};
use dojo::world::WorldStorage;
use caps::helpers::{get_piece_locations, get_player_pieces};

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Global {
    #[key]
    pub key: u64,
    pub games_counter: u64,
    pub cap_counter: u64,
}


#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct Square {
    #[key]
    pub game_id: u64,
    #[key]
    pub x: u64,
    #[key]
    pub y: u64,
    pub ids: Array<u64>,
}

#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct Game {
    #[key]
    pub id: u64,
    pub player1: ContractAddress,
    pub player2: ContractAddress,
    pub caps_ids: Array<u64>,
    pub turn_count: u64,
    pub over: bool,
    pub active_start_of_turn_effects: Array<u64>,
    pub active_damage_step_effects: Array<u64>,
    pub active_move_step_effects: Array<u64>,
    pub active_end_of_turn_effects: Array<u64>,
}

#[generate_trait]
pub impl GameImpl of GameTrait {
    fn new(id: u64, player1: ContractAddress, player2: ContractAddress) -> Game {
        Game { id, player1, player2, caps_ids: ArrayTrait::new(), turn_count: 0, over: false, active_start_of_turn_effects: ArrayTrait::new(), active_damage_step_effects: ArrayTrait::new(), active_move_step_effects: ArrayTrait::new(), active_end_of_turn_effects: ArrayTrait::new() }
    }

    fn add_cap(ref self: Game, cap_id: u64) {
        self.caps_ids.append(cap_id);
    }

    fn remove_cap(ref self: Game, cap_id: u64) {
        let mut i = 0;
        let mut new_ids: Array<u64> = ArrayTrait::new();
        while i < self.caps_ids.len() {
            if *self.caps_ids[i] == cap_id {
                i += 1;
                continue;
            }
            new_ids.append(*self.caps_ids[i]);
            i += 1;
        };
        self.caps_ids = new_ids;
    }

    fn check_over(self: @Game, world: @WorldStorage) -> (bool, ContractAddress) {
        let mut i = 0;
        let mut one_found = false;
        let mut two_found = false;
        while i < self.caps_ids.len() {
            let cap: Cap = world.read_model(*self.caps_ids[i]);
            if cap.owner == *self.player1 {
                one_found = true;
            } else if cap.owner == *self.player2 {
                two_found = true;
            }
            i += 1;
        };
        if !one_found {
            return (true, *self.player2);
        } else if !two_found {
            return (true, *self.player1);
        }
        (false, starknet::contract_address_const::<0>())
    }

    fn add_effect(ref self: Game, effect: Effect) {
        match effect.get_timing() {
            Timing::StartOfTurn => {
                self.active_start_of_turn_effects.append(effect.effect_id);
            },
            Timing::DamageStep => {
                self.active_damage_step_effects.append(effect.effect_id);
            },
            Timing::MoveStep => {
                self.active_move_step_effects.append(effect.effect_id);
            },
            Timing::EndOfTurn => {
                self.active_end_of_turn_effects.append(effect.effect_id);
            },
        }
    }

}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Cap {
    #[key]
    pub id: u64,
    pub owner: ContractAddress,
    pub position: Vec2,
    pub cap_type: u16,
    pub dmg_taken: u16,
}

//This is never getting stored. It's just a model to generate the bindings
#[derive(Drop, Serde, Debug, Introspect)]
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



#[derive(Drop, Serde, Clone, Introspect)]
pub struct Action {
    pub cap_id: u64,
    pub action_type: ActionType,
}

#[derive(Drop, Serde, Clone, Introspect)]
pub enum ActionType {
    Move: Vec2,
    Attack: Vec2,
    Ability: Vec2,
}

#[generate_trait]
pub impl CapImpl of CapTrait {
    fn new(id: u64, owner: ContractAddress, position: Vec2, cap_type: u16) -> Cap {
        Cap { id, owner, position, cap_type, dmg_taken: 0 }
    }

    fn get_new_index_from_dir(self: @Cap, direction: u8, amt: u8) -> felt252 {
        let mut new_position = *self.position;
        match direction {
            0 => if new_position.x + amt > 6 {
                panic!("Move out of bounds");
            } else {
                new_position.x += amt
            },
            1 => if amt > new_position.x {
                panic!("Move out of bounds");
            } else {
                new_position.x -= amt
            },
            2 => if new_position.y + amt > 6 {
                panic!("Move out of bounds");
            } else {
                new_position.y += amt
            },
            3 => if amt > new_position.y {
                panic!("Move out of bounds");
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
                    panic!("Move out of bounds");
                }
                if amount > cap_type.move_range.x + bonus_range {
                    panic!("Move out of range");
                }
                new_position.x += amount;
            },
            1 => {
                if amount > new_position.x {
                    panic!("Move out of bounds");
                }
                if amount > cap_type.move_range.x + bonus_range {
                    panic!("Move out of range");
                }
                new_position.x -= amount;
            },
            2 => {
                if new_position.y + amount > 6 {
                    panic!("Move out of bounds");
                }
                if amount > cap_type.move_range.y + bonus_range {
                    panic!("Move out of range");
                }
                new_position.y += amount;
            },
            3 => {
                if amount > new_position.y {
                    panic!("Move out of bounds");
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

    fn use_ability(ref self: Cap, cap_type: CapType, target: Vec2, game_id: u64, ref world: WorldStorage) {
        let mut locations = get_piece_locations(game_id, @world);
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
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                cap_at_target.dmg_taken += 5;
                world.write_model(@cap_at_target);
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
                let mut game: Game = world.read_model(game_id);
                let mut i = 0;
                let mut new_effects: Array<u64> = ArrayTrait::new();
                let mut found = false;
                while i < game.active_damage_step_effects.len() {
                    let effect: Effect = world.read_model(*game.active_damage_step_effects.at(i));
                    match effect.effect_type {
                        EffectType::Shield(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == cap_at_target_id {
                                        let new_val = x + 5;
                                        let new_effect = Effect {
                                            game_id,
                                            effect_id: effect.effect_id,
                                            effect_type: EffectType::Shield(new_val),
                                            target: effect.target,
                                            remaining_triggers: effect.remaining_triggers,
                                        };
                                        found = true;
                                        world.write_model(@new_effect);
                                    }
                                },
                                _ => (),
                            }
                        },
                        _ => new_effects.append(effect.effect_id),
                    }
                    i += 1;
                };
                if !found {
                    let new_effect = Effect {
                        game_id,
                        effect_id: game.active_damage_step_effects.len().into(),
                        effect_type: EffectType::Shield(5),
                        target: EffectTarget::Cap(cap_at_target_id),
                        remaining_triggers: 1,
                    };
                    new_effects.append(new_effect.effect_id);
                    world.write_model(@new_effect);
                    game.active_damage_step_effects = new_effects;
                    world.write_model(@game);
                }
            },
            7 => {
                let mut game: Game = world.read_model(game_id);
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let effect = Effect {
                    game_id,
                    effect_id: game.active_damage_step_effects.len().into(),
                    effect_type: EffectType::AbilityDiscount(1),
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 1,
                };
                world.write_model(@effect);
                game.add_effect(effect);
                world.write_model(@game);
            },
            8 => {
                let mut game: Game = world.read_model(game_id);
                let effect = Effect {
                    game_id,
                    effect_id: game.active_damage_step_effects.len().into(),
                    effect_type: EffectType::AttackBonus(self.dmg_taken.try_into().unwrap()),
                    target: EffectTarget::Cap(self.id),
                    remaining_triggers: 1,
                };
                world.write_model(@effect);
                game.add_effect(effect);
                world.write_model(@game);
            },
            9 => {
                let mut game: Game = world.read_model(game_id);
                let amt = self.dmg_taken;
                if amt == 0 {
                    panic!("No damage taken to heal");
                }
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                let cap_type = get_cap_type(cap_at_target.cap_type);
                let remaining_health = cap_type.unwrap().base_health - cap_at_target.dmg_taken;
                if amt > remaining_health {
                    game.remove_cap(cap_at_target_id);
                    world.write_model(@game);
                    world.erase_model(@cap_at_target);
                }
                else {
                    cap_at_target.dmg_taken += amt;
                    world.write_model(@cap_at_target);
                }
                self.dmg_taken = 0;
                world.write_model(@self);
            },
            10 => {
                let mut game: Game = world.read_model(game_id);
                let mut i = 0;
                while i < game.active_damage_step_effects.len() {
                    let effect: Effect = world.read_model(*game.active_damage_step_effects.at(i));
                    match effect.effect_type {
                        EffectType::Shield(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == self.id {
                                        let cap_type = get_cap_type(self.cap_type);
                                        let new_effect = Effect {
                                            game_id,
                                            effect_id: effect.effect_id,
                                            effect_type: EffectType::AttackDiscount(cap_type.unwrap().attack_dmg.try_into().unwrap()),
                                            target: effect.target,
                                            remaining_triggers: x,
                                        };
                                        game.add_effect(new_effect);
                                        world.write_model(@new_effect);
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
            11 => {
                //none
                let mut game: Game = world.read_model(game_id);
                let mut i = 0;
                while i < game.active_start_of_turn_effects.len() {
                    let effect: Effect = world.read_model(*game.active_start_of_turn_effects.at(i));
                    match effect.effect_type {
                        EffectType::ExtraEnergy(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == self.id {
                                        let new_effect = Effect {
                                            game_id,
                                            effect_id: effect.effect_id,
                                            effect_type: EffectType::AttackBonus(x.try_into().unwrap()),
                                            target: effect.target,
                                            remaining_triggers: 1,
                                        };
                                        game.add_effect(new_effect);
                                        world.write_model(@new_effect);
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
            12 => {
                //none
                let mut game: Game = world.read_model(game_id);
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                let target_cap_type = get_cap_type(cap_at_target.cap_type);
                if target_cap_type.unwrap().base_health - cap_at_target.dmg_taken == 1 {
                    game.remove_cap(cap_at_target_id);
                    world.write_model(@game);
                    world.erase_model(@cap_at_target);
                }
                else {
                    cap_at_target.dmg_taken += 1;
                    let effect = Effect {
                        game_id,
                        effect_id: game.active_damage_step_effects.len().into(),
                        effect_type: EffectType::DamageBuff(3),
                        target: EffectTarget::Cap(cap_at_target_id),
                        remaining_triggers: 1,
                    };
                    game.add_effect(effect);
                    world.write_model(@effect);
                    world.write_model(@game);
                    world.write_model(@cap_at_target);
                }
            },
            13 => {
                let mut game: Game = world.read_model(game_id);
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut effect = Effect {
                    game_id,
                    effect_id: game.active_damage_step_effects.len().into(),
                    effect_type: EffectType::Stun,
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 1,
                };
                game.add_effect(effect);
                world.write_model(@effect);
                world.write_model(@game);
            },
            14 => {
                let mut game: Game = world.read_model(game_id);
                let mut i = 0;
                while i < game.active_damage_step_effects.len() {
                    let effect: Effect = world.read_model(*game.active_damage_step_effects.at(i));
                    match effect.effect_type {
                        EffectType::Shield(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == self.id {
                                        let new_effect = Effect {
                                            game_id,
                                            effect_id: effect.effect_id,
                                            effect_type: EffectType::MoveDiscount(x.try_into().unwrap()),
                                            target: effect.target,
                                            remaining_triggers: x,
                                        };
                                        game.add_effect(new_effect);
                                        world.write_model(@new_effect);
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
                let mut game: Game = world.read_model(game_id);
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut effect = Effect {
                    game_id,
                    effect_id: game.active_damage_step_effects.len().into(),
                    effect_type: EffectType::Double,
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 1,
                };
                game.add_effect(effect);
                world.write_model(@effect);
                world.write_model(@game);
            },
            16 => {
                //none
                let mut game: Game = world.read_model(game_id);
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut effect = Effect {
                    game_id,
                    effect_id: game.active_damage_step_effects.len().into(),
                    effect_type: EffectType::DOT(1),
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 3,
                };
                game.add_effect(effect);
                world.write_model(@effect);
                world.write_model(@game);
            },
            17 => {
                let mut game: Game = world.read_model(game_id);
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut effect = Effect {
                    game_id,
                    effect_id: game.active_damage_step_effects.len().into(),
                    effect_type: EffectType::Heal(2),
                    target: EffectTarget::Cap(cap_at_target_id),
                    remaining_triggers: 3,
                };
                game.add_effect(effect);
                world.write_model(@effect);
                world.write_model(@game);
            },
            18 => {
                let mut game: Game = world.read_model(game_id);
                let mut i = 0;
                while i < game.active_damage_step_effects.len() {
                    let effect: Effect = world.read_model(*game.active_damage_step_effects.at(i));
                    match effect.effect_type {
                        EffectType::Shield(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == self.id {
                                        let new_effect = Effect {
                                            game_id,
                                            effect_id: effect.effect_id,
                                            effect_type: EffectType::Shield(x * 2),
                                            target: effect.target,
                                            remaining_triggers: 1,
                                        };
                                        game.add_effect(new_effect);
                                        world.write_model(@game);
                                        world.write_model(@new_effect);
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
            19 => {
                //none
                let mut game: Game = world.read_model(game_id);
                let mut energy_effect = Effect {
                    game_id,
                    effect_id: game.active_damage_step_effects.len().into(),
                    effect_type: EffectType::ExtraEnergy(2),
                    target: EffectTarget::Cap(self.id),
                    remaining_triggers: 1,
                };
                game.add_effect(energy_effect);
                let stun_effect = Effect {
                    game_id,
                    effect_id: game.active_damage_step_effects.len().into(),
                    effect_type: EffectType::Stun,
                    target: EffectTarget::Cap(self.id),
                    remaining_triggers: 1,
                };
                game.add_effect(stun_effect);
                let mut i = 0;
                let mut active_shield = false;
                while i < game.active_damage_step_effects.len() {
                    let effect: Effect = world.read_model(*game.active_damage_step_effects.at(i));
                    match effect.effect_type {
                        EffectType::Shield(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == self.id {
                                        let new_effect = Effect {
                                            game_id,
                                            effect_id: effect.effect_id,
                                            effect_type: EffectType::Shield(x + 2),
                                            target: effect.target,
                                            remaining_triggers: 1,
                                        };
                                        active_shield = true;
                                        game.add_effect(new_effect);
                                        world.write_model(@new_effect);
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
                if !active_shield {
                    let new_effect = Effect {
                        game_id,
                        effect_id: game.active_damage_step_effects.len().into(),
                        effect_type: EffectType::Shield(2),
                        target: EffectTarget::Cap(self.id),
                        remaining_triggers: 1,
                    };
                    game.add_effect(new_effect);
                    world.write_model(@new_effect);
                }
                world.write_model(@energy_effect);
                world.write_model(@game);
            },
            20 => {
                let mut game: Game = world.read_model(game_id);
                let self_cap_type = get_cap_type(self.cap_type);
                let target_id = locations.get((target.x * 7 + target.y).into());
                let mut target_cap: Cap = world.read_model(target_id);
                let target_cap_type = get_cap_type(target_cap.cap_type);
                
                let self_health = self_cap_type.unwrap().base_health - self.dmg_taken;
                let target_health = target_cap_type.unwrap().base_health - target_cap.dmg_taken;
                
                if self_health < 5 {
                    panic!("Not enough health, ability would kill self");
                }
                if target_health < 7 {
                    game.remove_cap(target_id);
                    self.dmg_taken += 4;
                    world.write_model(@self);
                    world.write_model(@game);
                    world.erase_model(@target_cap);
                }
                else {
                    target_cap.dmg_taken += 7;
                    self.dmg_taken += 4;
                    world.write_model(@self);
                    world.write_model(@target_cap);
                }
            },
            21 => {
                let mut game: Game = world.read_model(game_id);
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                let cap_at_target_type = get_cap_type(cap_at_target.cap_type);
                let cap_at_target_health = cap_at_target_type.unwrap().base_health - cap_at_target.dmg_taken;
                
                if cap_at_target_health < 9 {
                    world.erase_model(@cap_at_target);
                    let effect = Effect {
                        game_id,
                        effect_id: game.active_damage_step_effects.len().into(),
                        effect_type: EffectType::Stun,
                        target: EffectTarget::Cap(self.id),
                        remaining_triggers: 1,
                    };
                    game.add_effect(effect);
                    game.remove_cap(cap_at_target_id);
                    world.write_model(@effect);
                    world.write_model(@game);
                }
                else {
                    cap_at_target.dmg_taken += 9;
                    world.write_model(@cap_at_target);
                }
            },
            22 => {
                //none
                let mut game: Game = world.read_model(game_id);
                let cap_at_target_id = locations.get((target.x * 7 + target.y).into());
                let mut cap_at_target: Cap = world.read_model(cap_at_target_id);
                let cap_at_target_type = get_cap_type(cap_at_target.cap_type);
                
                let mut i = 0;
                let mut ally_shield = 0;
                while i < game.active_damage_step_effects.len() {
                    let effect: Effect = world.read_model(*game.active_damage_step_effects.at(i));
                    match effect.effect_type {
                        EffectType::Shield(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == cap_at_target_id {
                                        ally_shield += x;
                                    }
                                },
                                _ => (),
                            }
                        },
                        _ => (),
                    }
                    i += 1;
                };
                let mut i = 0;
                let mut found_shield = false;
                while i < game.active_damage_step_effects.len() {
                    let effect: Effect = world.read_model(*game.active_damage_step_effects.at(i));
                    match effect.effect_type {
                        EffectType::Shield(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == cap_at_target_id {
                                        let new_effect = Effect {
                                            game_id,
                                            effect_id: effect.effect_id,
                                            effect_type: EffectType::Shield(x + ally_shield),
                                            target: effect.target,
                                            remaining_triggers: 1,
                                        };
                                        found_shield = true;
                                        world.write_model(@new_effect);
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
                if !found_shield {
                    let new_effect = Effect {
                        game_id,
                        effect_id: game.active_damage_step_effects.len().into(),
                        effect_type: EffectType::Shield(ally_shield),
                        target: EffectTarget::Cap(cap_at_target_id),
                        remaining_triggers: 1,
                    };
                    game.add_effect(new_effect);
                    world.write_model(@new_effect);
                }
                world.write_model(@game);
            },
            23 => {
                //none
                let mut game: Game = world.read_model(game_id);
                let player_pieces = get_player_pieces(game_id, game.player1, @world);

                let mut i = 0;
                let mut extra_energy = 0;
                while i < game.active_start_of_turn_effects.len() {
                    let effect: Effect = world.read_model(*game.active_start_of_turn_effects.at(i));
                    match effect.effect_type {
                        EffectType::ExtraEnergy(x) => {
                            extra_energy += x.into();
                        },
                        _ => (),
                    }
                    i += 1;
                };
                
                let mut i = 0;
                while i < player_pieces.len() {
                    let mut piece: Cap = world.read_model(*player_pieces[i]);
                    if piece.dmg_taken > 2 + extra_energy {
                        piece.dmg_taken = 0;
                        world.write_model(@piece);
                    }
                    else {
                        piece.dmg_taken -= 2 + extra_energy;
                        world.write_model(@piece);
                    }
                    
                    
                    i += 1;
                };
            },
            _ => panic!("Not yet implemented"),
        }
    }

}

#[derive(Copy, Drop, Serde, Clone, Debug, PartialEq, Introspect)]
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
    fn is_valid(self: @TargetType, cap: @Cap, cap_type: CapType, target: Vec2, game_id: u64, world: @WorldStorage) -> bool {
        match *self {
            TargetType::None => false,
            TargetType::SelfCap => {
                true
            },
            TargetType::TeamCap => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                let in_range = cap.check_in_range(target, @cap_type.ability_range);
                assert!(in_range, "Target not in range");
                let mut locations = get_piece_locations(game_id, world);
                let at_location_index = locations.get((target.x * 7 + target.y).into());
                assert!(at_location_index != 0, "No cap at location");
                let at_location: Cap = world.read_model(at_location_index);
                //Must be player
                assert!(at_location.owner == *cap.owner, "Cap is not owned by player");
                if in_range && at_location.owner == *cap.owner {
                    return true;
                }
                false
            },
            TargetType::OpponentCap => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                let in_range = cap.check_in_range(target, @cap_type.ability_range);
                assert!(in_range, "Target not in range");
                let mut locations = get_piece_locations(game_id, world);
                let at_location_index = locations.get((target.x * 7 + target.y).into());
                assert!(at_location_index != 0, "No cap at location");
                let at_location: Cap = world.read_model(at_location_index);
                assert!(*cap.owner != starknet::contract_address_const::<0x0>(), "Cap owner 0?");
                assert!(at_location.owner != *cap.owner, "Cap is owned by player");
                //Must be opponent
                if in_range && at_location.owner != *cap.owner {
                    return true;
                }
                false
            },
            TargetType::AnyCap => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                let in_range = cap.check_in_range(target, @cap_type.ability_range);
                assert!(in_range, "Target not in range");
                let mut locations = get_piece_locations(game_id, world);
                let at_location_index = locations.get((target.x * 7 + target.y).into());
                if at_location_index != 0 && in_range {
                    return true;
                }
                false
            },
            TargetType::AnySquare => {
                assert!(cap_type.ability_range.len() > 0, "Ability range is empty");
                cap.check_in_range(target, @cap_type.ability_range)
                
            },
        }
    }
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect, Debug)]
pub struct Vec2 {
    pub x: u8,
    pub y: u8,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
#[dojo::model]
pub struct Effect {
    #[key]
    pub game_id: u64,
    #[key]
    pub effect_id: u64,
    pub effect_type: EffectType,
    pub target: EffectTarget,
    pub remaining_triggers: u8,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum EffectType {
    DamageBuff: u8,
    Shield: u8,
    Heal: u8,
    DOT: u8,
    MoveBonus: u8,
    AttackBonus: u8,
    BonusRange: u8,
    MoveDiscount: u8,
    AttackDiscount: u8,
    AbilityDiscount: u8,
    ExtraEnergy: u8,
    Stun,
    Double,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum EffectTarget {
    Cap: u64,
    Square: Vec2,
}

#[generate_trait]
pub impl EffectImpl of EffectTrait {
    fn get_timing(self: @Effect) -> Timing {
        match self.effect_type {
            EffectType::DamageBuff => Timing::DamageStep,
            EffectType::Shield => Timing::DamageStep,
            EffectType::Heal => Timing::StartOfTurn,
            EffectType::DOT => Timing::EndOfTurn,
            EffectType::MoveBonus => Timing::MoveStep,
            EffectType::AttackBonus => Timing::DamageStep,
            EffectType::BonusRange => Timing::DamageStep,
            EffectType::MoveDiscount => Timing::MoveStep,
            EffectType::AttackDiscount => Timing::MoveStep,
            EffectType::AbilityDiscount => Timing::MoveStep,
            EffectType::ExtraEnergy => Timing::StartOfTurn,
            EffectType::Stun => Timing::EndOfTurn,
            EffectType::Double => Timing::EndOfTurn,
        }
    }
}

#[derive(Copy, Drop, Serde, Introspect)]
pub enum Timing {
    StartOfTurn,
    DamageStep,
    MoveStep,
    EndOfTurn,
}

#[generate_trait]
impl Vec2Impl of Vec2Trait {
    fn is_zero(self: Vec2) -> bool {
        if self.x - self.y == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Vec2, b: Vec2) -> bool {
        self.x == b.x && self.y == b.y
    }
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
            attack_cost: 2,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_description: "Deal 5 damage to an enemy",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 4,
            base_health: 5,
            ability_target: TargetType::OpponentCap,
            ability_cost: 3,
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
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::TeamCap,
            ability_cost: 2,
        }),
        6 => Option::Some(CapType {
            id: 6,
            name: "Yellow Basic",
            description: "Cap 5",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Shield an ally for 5",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::TeamCap,
            ability_cost: 2,
        }),
        7 => Option::Some(CapType {
            id: 7,
            name: "Green Basic",
            description: "Cap 6",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Target unit's next ability use costs 1 less energy",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::TeamCap,
            ability_cost: 2,

        }),
        8 => Option::Some(CapType {
            id: 8,
            name: "Red Elite",
            description: "Cap 8",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_description: "Next attack deals 1 more damage for each damage this unit has taken",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 4,
            base_health: 5,
            ability_target: TargetType::OpponentCap,
            ability_cost: 3,
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
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::TeamCap,
            ability_cost: 2,
        }),
        10 => Option::Some(CapType {
            id: 10,
            name: "Yellow Elite",
            description: "Cap 10",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Gain free attacks equal to the strength of this cards shield",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        11 => Option::Some(CapType {
            id: 11,
            name: "Green Elite",
            description: "Cap 11",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Next attack deals 1 more damage for each extra energy you started this turn with",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        12 => Option::Some(CapType {
            id: 12,
            name: "Red Mage",
            description: "Red Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "Deal 1 damage to an ally to make its next attack deal 3 more damage",
            move_range: Vec2 { x: 1, y: 1 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::TeamCap,
            ability_cost: 0,
        }),
        13 => Option::Some(CapType {
            id: 13,
            name: "Blue Mage",
            description: "Blue Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "Stun a target enemy unit",
            move_range: Vec2 { x: 1, y: 1 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::OpponentCap,
            ability_cost: 0,
        }),
        14 => Option::Some(CapType {
            id: 14,
            name: "Yellow Mage",
            description: "Yellow Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "Target unit gains move range equal to its shield health",
            move_range: Vec2 { x: 1, y: 1 },
            attack_dmg: 1,
            base_health: 10,
                ability_target: TargetType::TeamCap,
            ability_cost: 0,
        }),
        15 => Option::Some(CapType {
            id: 15,
            name: "Green Mage",
            description: "Green Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "Repeat the effect of the ally's next ability (if possible)",
            move_range: Vec2 { x: 1, y: 1 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::TeamCap,
            ability_cost: 0,
        }),
        16 => Option::Some(CapType {
            id: 16,
            name: "Red Basic",
            description: "Cap 3",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_description: "Inflict target with burn that deals 1 damage each turn for 3 turns",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 4,
            base_health: 5,
            ability_target: TargetType::OpponentCap,
            ability_cost: 3,
        }),
        17 => Option::Some(CapType {
            id: 17,
            name: "Blue Basic",
            description: "Cap 4",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Target unit heals 2 health per turn at the end of the next 3 turns",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::TeamCap,
            ability_cost: 2,
        }),
        18 => Option::Some(CapType {
            id: 18,
            name: "Yellow Basic",
            description: "Cap 5",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Double the strength of this unit's shield",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        19 => Option::Some(CapType {
            id: 19,
            name: "Green Tank",
            description: "Green Tank",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Next turn gain 2 energy. This card becomes stunned next turn and recieves a 2 health shield",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        20 => Option::Some(CapType {
            id: 20,
            name: "Red Elite",
            description: "Cap 8",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_description: "Deal 4 damage to self and 7 damage to an enemy",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 4,
            base_health: 5,
            ability_target: TargetType::OpponentCap,
            ability_cost: 3,
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
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::OpponentCap,
            ability_cost: 2,
        }),
        22 => Option::Some(CapType {
            id: 22,
            name: "Yellow Elite",
            description: "Cap 10",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Gain shield equal to target unit's shield",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::TeamCap,
            ability_cost: 2,
        }),
        23 => Option::Some(CapType {
            id: 23,
            name: "Green Elite",
            description: "Cap 11",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Heal all allies for 2 health, plus 1 health per extra energy you started this turn with",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        _ => Option::None,
    };
    res
}