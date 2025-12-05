// Test function for complex type input from WASM

#[derive(Copy, Drop, Serde, PartialEq, Debug)]
pub struct Vec2 {
    pub x: u8,
    pub y: u8,
}

#[derive(Drop, Serde, Copy)]
pub enum ActionType {
    Play: Vec2,
    Move: Vec2,
    Attack: Vec2,
    Ability: Vec2,
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

// Test function that takes a Game and an ActionType, returns some computed value
pub fn main(game: Game, action: ActionType) -> (u64, u8, u8) {
    let (action_value, target_x, target_y) = match action {
        ActionType::Play(pos) => (1_u64, pos.x, pos.y),
        ActionType::Move(pos) => (2_u64, pos.x, pos.y),
        ActionType::Attack(pos) => (3_u64, pos.x, pos.y),
        ActionType::Ability(pos) => (4_u64, pos.x, pos.y),
    };
    
    // Return: (game.turn_count + action_value, target_x, target_y)
    (game.turn_count + action_value, target_x, target_y)
}

