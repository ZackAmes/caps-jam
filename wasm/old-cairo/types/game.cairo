use starknet::{ContractAddress};
use caps_wasm::types::effect::Effect;
use caps_wasm::types::cap::Cap;

#[derive(Copy, Drop, Serde, Debug)]
pub struct Global {
    pub key: u64,
    pub games_counter: u64,
    pub cap_counter: u64,
}

#[derive(Drop, Serde, Debug, Clone)]
pub struct Game {
    pub id: u64,
    pub player1: felt252,
    pub player2: felt252,
    pub caps_ids: Array<u64>,
    pub turn_count: u64,
    pub over: bool,
    pub effect_ids: Array<u64>,
    pub last_action_timestamp: u64,
}

#[generate_trait]
pub impl GameImpl of GameTrait {
    fn new(id: u64, player1: felt252, player2: felt252) -> Game {
        Game {
            id,
            player1,
            player2,
            caps_ids: ArrayTrait::new(),
            turn_count: 0,
            over: false,
            effect_ids: ArrayTrait::new(),
            last_action_timestamp: 0,
        }
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

    fn check_over_simulated(self: @Game, caps: @Array<Cap>) -> (bool, felt252) {
        let mut i = 0;
        let mut one_found = false;
        let mut two_found = false;
        let mut winner: felt252 = 0;
        while i < caps.len() {
            let cap: Cap = *caps.at(i);
            if cap.owner == *self.player1 {
                one_found = true;
                winner = *self.player1;
                break;
            }
            if cap.owner == *self.player2 {
                two_found = true;
                winner = *self.player2;
                break;
            }
            i += 1;
        };
        (one_found && two_found, winner)
    }
}


#[derive(Drop, Serde, Copy)]
pub struct Action {
    pub cap_id: u64,
    pub action_type: ActionType,
}

#[derive(Drop, Serde, Copy)]
pub enum ActionType {
    Move: Vec2,
    Attack: Vec2,
    Ability: Vec2,
}

#[derive(Copy, Drop, Serde, PartialEq, Debug)]
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

