use starknet::{ContractAddress};
use dojo::model::{ModelStorage};
use dojo::world::WorldStorage;
use caps::models::effect::{Effect, EffectTrait, Timing};
use caps::models::cap::{Cap, CapType};
use caps::sets::set_zero::get_cap_type;

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct Global {
    #[key]
    pub key: u64,
    pub games_counter: u64,
    pub cap_counter: u64,
}

#[derive(Drop, Serde, Debug, Clone)]
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
    pub active_move_step_effects: Array<u64>,
    pub active_end_of_turn_effects: Array<u64>,
    pub effect_ids: Array<u64>,
    pub last_action_timestamp: u64,
}

#[generate_trait]
pub impl GameImpl of GameTrait {
    fn new(id: u64, player1: ContractAddress, player2: ContractAddress) -> Game {
        Game { id, player1, player2, caps_ids: ArrayTrait::new(), turn_count: 0, over: false, active_start_of_turn_effects: ArrayTrait::new(), active_move_step_effects: ArrayTrait::new(), active_end_of_turn_effects: ArrayTrait::new(),  effect_ids: ArrayTrait::new(), last_action_timestamp: 0 }
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

    fn remove_effect(ref self: Game, effect: Effect) {
        let mut i = 0;
        let mut new_effects: Array<u64> = ArrayTrait::new();
        match effect.get_timing() {
            Timing::StartOfTurn => {
                while i < self.active_start_of_turn_effects.len() {
                    if *self.active_start_of_turn_effects.at(i) != effect.effect_id {
                        new_effects.append(*self.active_start_of_turn_effects.at(i));
                    }
                    i += 1;
                };
                self.active_start_of_turn_effects = new_effects;
            },
            Timing::MoveStep => {
                while i < self.active_move_step_effects.len() {
                    if *self.active_move_step_effects.at(i) != effect.effect_id {
                        new_effects.append(*self.active_move_step_effects.at(i));
                    }
                    i += 1;
                };
                self.active_move_step_effects = new_effects;
            },
            Timing::EndOfTurn => {
                while i < self.active_end_of_turn_effects.len() {
                    if *self.active_end_of_turn_effects.at(i) != effect.effect_id {
                        new_effects.append(*self.active_end_of_turn_effects.at(i));
                    }
                    i += 1;
                };
                self.active_end_of_turn_effects = new_effects;
            },
        };
        let mut i = 0;
        let mut new_ids: Array<u64> = ArrayTrait::new();
        while i < self.effect_ids.len() {
            if *self.effect_ids.at(i) != effect.effect_id {
                new_ids.append(*self.effect_ids.at(i));
            }
            i += 1;
        };
        self.effect_ids = new_ids;
    }

    fn check_over(self: @Game, world: @WorldStorage) -> (bool, ContractAddress) {
        let mut i = 0;
        let mut one_found = false;
        let mut two_found = false;
        while i < self.caps_ids.len() {
            let cap: Cap = world.read_model(*self.caps_ids[i]);
            let cap_type = get_cap_type(cap.cap_type).unwrap();
            if cap.dmg_taken >= cap_type.base_health {
                i+=1;
                continue;
            }
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

    fn add_new_effect(ref self: Game, effect: Effect) {
        match effect.get_timing() {
            Timing::StartOfTurn => {
                self.active_start_of_turn_effects.append(effect.effect_id);
            },
            Timing::MoveStep => {
                self.active_move_step_effects.append(effect.effect_id);
            },
            Timing::EndOfTurn => {
                self.active_end_of_turn_effects.append(effect.effect_id);
            },
        }
        self.effect_ids.append(effect.effect_id);
    }

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

#[derive(Copy, Drop, Serde, PartialEq, Introspect, Debug)]
pub struct Vec2 {
    pub x: u8,
    pub y: u8,
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

