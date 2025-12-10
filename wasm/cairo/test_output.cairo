// Test function for complex type output from Cairo to WASM
// Tests all enum types as return values

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
    Attack: Vec2,
    Ability: Vec2,
}

#[derive(Copy, Drop, Serde, Debug, PartialEq)]
pub enum TargetType {
    None,
    SelfCap,
    TeamCap,
    OpponentCap,
    AnyCap,
    AnySquare,
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

// Main function that returns a Location enum
// Takes a Location enum as input and returns it
pub fn main(location: Location) -> Location {
    location
}

