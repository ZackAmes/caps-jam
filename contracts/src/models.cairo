use starknet::{ContractAddress};
use dojo::model::{ModelStorage};
use dojo::world::WorldStorage;

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
pub struct Game {
    #[key]
    pub id: u64,
    pub player1: ContractAddress,
    pub player2: ContractAddress,
    pub caps_ids: Array<u64>,
}

#[generate_trait]
pub impl GameImpl of GameTrait {
    fn new(id: u64, player1: ContractAddress, player2: ContractAddress) -> Game {
        Game { id, player1, player2, caps_ids: ArrayTrait::new() }
    }

    fn add_cap(ref self: Game, cap_id: u64) {
        self.caps_ids.append(cap_id);
    }

    fn check_over(self: Game, world: @WorldStorage) -> (bool, ContractAddress) {
        let mut i = 0;
        let mut one_found = false;
        let mut two_found = false;
        while i < self.caps_ids.len() {
            let cap: Cap = world.read_model(*self.caps_ids[i]);
            if cap.owner == self.player1 {
                one_found = true;
            } else if cap.owner == self.player2 {
                two_found = true;
            }
            i += 1;
        };
        if !one_found {
            return (true, self.player2);
        } else if !two_found {
            return (true, self.player1);
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
}

#[generate_trait]
pub impl CapImpl of CapTrait {
    fn new(id: u64, owner: ContractAddress, position: Vec2) -> Cap {
        Cap { id, owner, position }
    }
}

#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
pub struct Vec2 {
    pub x: u32,
    pub y: u32,
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
