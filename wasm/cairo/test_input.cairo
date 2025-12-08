// Test function for complex type input from WASM

#[derive(Copy, Drop, Serde, PartialEq, Debug)]
pub struct Vec2 {
    pub x: u8,
    pub y: u8,
}

#[derive(Copy, Drop, Serde, Debug, PartialEq)]
pub enum Location {
    Bench,
    Board: Vec2,
    Dead,
}

#[derive(Drop, Serde, Copy)]
pub enum ActionType {
    Play: Vec2,
    Move: Vec2,
}

// Test function that takes a Location and ActionType, returns what it parsed
pub fn main(location: Location, action: ActionType) -> (u8, u8, u8, u8, u8) {
    // Return location info
    let (loc_type, loc_x, loc_y) = match location {
        Location::Bench => (0_u8, 0_u8, 0_u8),
        Location::Board(pos) => (1_u8, pos.x, pos.y),
        Location::Dead => (2_u8, 0_u8, 0_u8),
    };
    
    // Return action info
    let (action_type, target_x, _target_y) = match action {
        ActionType::Play(pos) => (0_u8, pos.x, pos.y),
        ActionType::Move(pos) => (1_u8, pos.x, pos.y),
    };
    
    (loc_type, loc_x, loc_y, action_type, target_x)
}
