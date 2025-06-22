use starknet::{ContractAddress};
use dojo::model::{ModelStorage};
use dojo::world::WorldStorage;
use caps::helpers::get_piece_locations;

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

    fn move(ref self: Cap, cap_type: CapType, direction: u8, amount: u8){
        let mut new_position = self.position;
        match direction {
            0 => {
                if new_position.x + amount > 6 {
                    panic!("Move out of bounds");
                }
                if amount > cap_type.move_range.x {
                    panic!("Move out of range");
                }
                new_position.x += amount;
            },
            1 => {
                if amount > new_position.x {
                    panic!("Move out of bounds");
                }
                if amount > cap_type.move_range.x {
                    panic!("Move out of range");
                }
                new_position.x -= amount;
            },
            2 => {
                if new_position.y + amount > 6 {
                    panic!("Move out of bounds");
                }
                if amount > cap_type.move_range.y {
                    panic!("Move out of range");
                }
                new_position.y += amount;
            },
            3 => {
                if amount > new_position.y {
                    panic!("Move out of bounds");
                }
                if amount > cap_type.move_range.y {
                    panic!("Move out of range");
                }
                new_position.y -= amount;
            },
            _ => (),
        };
        self.position = new_position;
    }

    fn check_in_range(self: @Cap, target: Vec2, range: Array<Vec2>) -> bool {
        let mut valid = false;
        let mut i = 0;
        while i < range.len() {
            let to_check: Vec2 = *range[i];
            if target.x >= *self.position.x && target.y >= *self.position.y {
                if to_check.x + *self.position.x > 6 {
                    i+=1;
                    continue;
                }
                if to_check.y + *self.position.y > 6 {
                    i+=1;
                    continue;
                }
                if *self.position.x + to_check.x == target.x && *self.position.y + to_check.y == target.y {
                    valid = true;
                    break;
                }
                else {
                    i+=1;
                    continue;
                }
            }
            else if target.x <= *self.position.x && target.y <= *self.position.y {
                if to_check.x > *self.position.x {
                    i+=1;
                    continue;
                }
                if to_check.y > *self.position.y {
                    i+=1;
                    continue;
                }
                if *self.position.x - to_check.x == target.x && *self.position.y - to_check.y == target.y {
                    valid = true;
                    break;
                }
                else {
                    i+=1;
                    continue;
                }
            }
            else if target.x <= *self.position.x && target.y >= *self.position.y {
                if to_check.x > *self.position.x  {
                    i+=1;
                    continue;
                }
                if to_check.y + *self.position.y > 6 {
                    i+=1;
                    continue;
                }
                if *self.position.x - to_check.x == target.x && *self.position.y + to_check.y == target.y {
                    valid = true;
                    break;
                }
                else {
                    i+=1;
                    continue;
                }
            }
            else if target.x >= *self.position.x && target.y <= *self.position.y {
                if to_check.x + *self.position.x > 6 {
                    i+=1;
                    continue;
                }
                if to_check.y > *self.position.y {
                    i+=1;
                    continue;
                }
                if *self.position.x + to_check.x == target.x && *self.position.y - to_check.y == target.y {
                    valid = true;
                    break;
                }
                else {
                    i+=1;
                    continue;
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
                let in_range = cap.check_in_range(target, cap_type.ability_range);
                let mut locations = get_piece_locations(game_id, world);
                let at_location_index = locations.get((*cap.position.x * 7 + *cap.position.y).into());
                let at_location: Cap = world.read_model(at_location_index);
                //Must be player
                if in_range && at_location.owner == *cap.owner {
                    return true;
                }
                false
            },
            TargetType::OpponentCap => {
                let in_range = cap.check_in_range(target, cap_type.ability_range);
                let mut locations = get_piece_locations(game_id, world);
                let at_location_index = locations.get((*cap.position.x * 7 + *cap.position.y).into());
                let at_location: Cap = world.read_model(at_location_index);
                //Must be opponent
                if in_range && at_location.owner != *cap.owner {
                    return true;
                }
                false
            },
            TargetType::AnyCap => {
                let in_range = cap.check_in_range(target, cap_type.ability_range);
                let mut locations = get_piece_locations(game_id, world);
                let at_location_index = locations.get((*cap.position.x * 7 + *cap.position.y).into());
                if at_location_index != 0 && in_range {
                    return true;
                }
                false
            },
            TargetType::AnySquare => {
                cap.check_in_range(target, cap_type.ability_range)
                
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
            EffectType::Stun => Timing::MoveStep,
            EffectType::Double => Timing::DamageStep,
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
