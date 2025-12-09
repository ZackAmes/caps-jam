// Test function for complex type input from WASM
// Matches all enums from simulate.cairo

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

// Test function that takes all enum types and an array to test empty array handling
// This helps verify serialization is working correctly
pub fn main(
    location: Location,
    action: ActionType,
    target_type: TargetType,
    effect_type: EffectType,
    effect_target: EffectTarget,
    test_array: Array<u64>,
) -> (u8, u8, u8, u8, u8, u8, u8, u8, u8, u8, u64, u8, u8, u64) {
    // Return location info: (variant, x, y)
    let (loc_variant, loc_x, loc_y) = match location {
        Location::Bench => (0_u8, 0_u8, 0_u8),
        Location::Board(pos) => (1_u8, pos.x, pos.y),
        Location::Dead => (2_u8, 0_u8, 0_u8),
    };
    
    // Return action info: (variant, x, y)
    let (action_variant, action_x, action_y) = match action {
        ActionType::Play(pos) => (0_u8, pos.x, pos.y),
        ActionType::Move(pos) => (1_u8, pos.x, pos.y),
        ActionType::Attack(pos) => (2_u8, pos.x, pos.y),
        ActionType::Ability(pos) => (3_u8, pos.x, pos.y),
    };
    
    // Return target_type variant
    let target_type_variant = match target_type {
        TargetType::None => 0_u8,
        TargetType::SelfCap => 1_u8,
        TargetType::TeamCap => 2_u8,
        TargetType::OpponentCap => 3_u8,
        TargetType::AnyCap => 4_u8,
        TargetType::AnySquare => 5_u8,
    };
    
    // Return effect_type info: (variant, payload)
    let (effect_type_variant, effect_payload) = match effect_type {
        EffectType::None => (0_u8, 0_u8),
        EffectType::DamageBuff(x) => (1_u8, x),
        EffectType::Shield(x) => (2_u8, x),
        EffectType::Heal(x) => (3_u8, x),
        EffectType::DOT(x) => (4_u8, x),
        EffectType::MoveBonus(x) => (5_u8, x),
        EffectType::AttackBonus(x) => (6_u8, x),
        EffectType::BonusRange(x) => (7_u8, x),
        EffectType::MoveDiscount(x) => (8_u8, x),
        EffectType::AttackDiscount(x) => (9_u8, x),
        EffectType::AbilityDiscount(x) => (10_u8, x),
        EffectType::ExtraEnergy(x) => (11_u8, x),
        EffectType::Stun(x) => (12_u8, x),
        EffectType::Double(x) => (13_u8, x),
    };
    
    // Return effect_target info: (variant, cap_id or x, y)
    let (effect_target_variant, effect_target_id, effect_target_x, effect_target_y) = match effect_target {
        EffectTarget::None => (0_u8, 0_u64, 0_u8, 0_u8),
        EffectTarget::Cap(id) => (1_u8, id, 0_u8, 0_u8),
        EffectTarget::Square(pos) => (2_u8, 0_u64, pos.x, pos.y),
    };
    
    // Return array length to verify it was received correctly
    let array_len: u64 = test_array.len().into();
    
    (
        loc_variant, loc_x, loc_y,
        action_variant, action_x, action_y,
        target_type_variant,
        effect_type_variant, effect_payload,
        effect_target_variant, effect_target_id, effect_target_x, effect_target_y,
        array_len,
    )
}

// Test function for EffectType enum
pub fn test_effect_type(effect: EffectType) -> (u8, u8) {
    match effect {
        EffectType::None => (0_u8, 0_u8),
        EffectType::DamageBuff(x) => (1_u8, x),
        EffectType::Shield(x) => (2_u8, x),
        EffectType::Heal(x) => (3_u8, x),
        EffectType::DOT(x) => (4_u8, x),
        EffectType::MoveBonus(x) => (5_u8, x),
        EffectType::AttackBonus(x) => (6_u8, x),
        EffectType::BonusRange(x) => (7_u8, x),
        EffectType::MoveDiscount(x) => (8_u8, x),
        EffectType::AttackDiscount(x) => (9_u8, x),
        EffectType::AbilityDiscount(x) => (10_u8, x),
        EffectType::ExtraEnergy(x) => (11_u8, x),
        EffectType::Stun(x) => (12_u8, x),
        EffectType::Double(x) => (13_u8, x),
    }
}

// Test function for EffectTarget enum
pub fn test_effect_target(target: EffectTarget) -> (u8, u64, u8, u8) {
    match target {
        EffectTarget::None => (0_u8, 0_u64, 0_u8, 0_u8),
        EffectTarget::Cap(id) => (1_u8, id, 0_u8, 0_u8),
        EffectTarget::Square(pos) => (2_u8, 0_u64, pos.x, pos.y),
    }
}

// Test function for TargetType enum
pub fn test_target_type(target: TargetType) -> u8 {
    match target {
        TargetType::None => 0_u8,
        TargetType::SelfCap => 1_u8,
        TargetType::TeamCap => 2_u8,
        TargetType::OpponentCap => 3_u8,
        TargetType::AnyCap => 4_u8,
        TargetType::AnySquare => 5_u8,
    }
}
