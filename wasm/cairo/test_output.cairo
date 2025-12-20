// Test function for complex type output from Cairo to WASM
// Tests the same signature as simulate.cairo to verify output serialization

#[derive(Copy, Drop, Serde, PartialEq, Debug)]
pub struct Vec2 {
    pub x: u8,
    pub y: u8,
}

#[derive(Copy, Drop, Serde, Debug)]
pub enum Location {
    Bench,
    Board: Vec2,
    Dead,
}

#[derive(Copy, Drop, Serde, Debug)]
pub struct Cap {
    pub id: u64,
    pub owner: felt252,
    pub location: Location,
    pub set_id: u64,
    pub cap_type: u16,
    pub dmg_taken: u16,
    pub shield_amt: u16,
}

#[derive(Drop, Serde, Copy)]
pub struct Action {
    pub cap_id: u64,
    pub action_type: ActionType,
}

#[derive(Drop, Serde, Copy)]
pub enum ActionType {
    Play: Vec2,
    Move: Vec2,
    Attack: Vec2,
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

#[derive(Copy, Drop, Serde, PartialEq)]
pub struct Effect {
    pub game_id: u64,
    pub effect_id: u64,
    pub effect_type: EffectType,
    pub target: EffectTarget,
    pub remaining_triggers: u8,
}

#[derive(Copy, Drop, Serde, PartialEq)]
pub enum EffectType {
    None,
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
    Stun: u8,
    Double: u8,
}

#[derive(Copy, Drop, Serde, PartialEq)]
pub enum EffectTarget {
    None,
    Cap: u64,
    Square: Vec2,
}

// Main function that takes 1 game, 1 cap, 1 effect
// Returns them to test output serialization
pub fn main(
    game: Game,
    cap: Cap,
    effect: Effect,
) -> (Game, Cap, Effect) {
    (game, cap, effect)
}

