// ============================================================================
// SIMULATE - Play, Move, Attack actions with Felt252Dict and CapType
// For compilation with: cairo-compile --single-file
// ============================================================================

use core::dict::Felt252Dict;

// ============================================================================
// TYPES
// ============================================================================

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
pub struct CapType {
    pub id: u16,
    pub base_health: u16,
    pub attack_dmg: u16,
}

// ============================================================================
// CAP TYPE LOOKUP (Basic set - first 4 types)
// ============================================================================

fn get_cap_type(cap_type_id: u16) -> Option<CapType> {
    match cap_type_id {
        0 => Option::Some(CapType { id: 0, base_health: 10, attack_dmg: 1 }),
        1 => Option::Some(CapType { id: 1, base_health: 10, attack_dmg: 1 }),
        2 => Option::Some(CapType { id: 2, base_health: 10, attack_dmg: 1 }),
        3 => Option::Some(CapType { id: 3, base_health: 10, attack_dmg: 1 }),
        4 => Option::Some(CapType { id: 4, base_health: 8, attack_dmg: 2 }),
        _ => Option::None,
    }
}

// ============================================================================
// HELPERS
// ============================================================================

fn get_position(cap: @Cap) -> Option<Vec2> {
    match cap.location {
        Location::Board(vec) => Option::Some(*vec),
        _ => Option::None,
    }
}

fn get_dicts_from_array(caps: @Array<Cap>) -> (Felt252Dict<u64>, Felt252Dict<Nullable<Cap>>) {
    let mut locations: Felt252Dict<u64> = Default::default();
    let mut keys: Felt252Dict<Nullable<Cap>> = Default::default();

    let mut i = 0;
    while i < caps.len() {
        let cap: Cap = *caps.at(i);
        let position = get_position(@cap);
        if position.is_some() {
            let pos = position.unwrap();
            let index: felt252 = (pos.x * 7 + pos.y).into();
            locations.insert(index, cap.id);
        }
        keys.insert(cap.id.into(), NullableTrait::new(cap));
        i += 1;
    };

    (locations, keys)
}

fn caps_from_dicts(
    cap_ids: @Array<u64>,
    ref keys: Felt252Dict<Nullable<Cap>>,
) -> Array<Cap> {
    let mut result: Array<Cap> = ArrayTrait::new();
    let mut i = 0;
    while i < cap_ids.len() {
        let cap_id = *cap_ids.at(i);
        let cap = keys.get(cap_id.into()).deref();
        result.append(cap);
        i += 1;
    };
    result
}

// Check if target is in attack range (adjacent squares for now)
fn is_in_range(from: Vec2, to: Vec2, range: u8) -> bool {
    let dx = if from.x > to.x { from.x - to.x } else { to.x - from.x };
    let dy = if from.y > to.y { from.y - to.y } else { to.y - from.y };
    dx <= range && dy <= range && (dx > 0 || dy > 0)
}

// Deal damage to a cap using its CapType for health
fn deal_damage(ref cap: Cap, amount: u16) {
    let cap_type = get_cap_type(cap.cap_type).unwrap();
    
    // Shield absorbs damage first
    if cap.shield_amt >= amount {
        cap.shield_amt -= amount;
    } else {
        let remaining = amount - cap.shield_amt;
        cap.shield_amt = 0;
        cap.dmg_taken += remaining;
        
        // Check if dead (using base_health from CapType)
        if cap.dmg_taken >= cap_type.base_health {
            cap.location = Location::Dead;
        }
    }
}

// ============================================================================
// PROCESS SINGLE ACTION
// ============================================================================

fn process_action(
    action: @Action,
    ref locations: Felt252Dict<u64>,
    ref keys: Felt252Dict<Nullable<Cap>>,
    caller: felt252,
) {
    let mut cap: Cap = keys.get((*action.cap_id).into()).deref();
    assert!(cap.owner == caller, "Not your cap");

    match action.action_type {
        ActionType::Play(target) => {
            match cap.location {
                Location::Bench => {},
                _ => { panic!("Cap not on bench"); },
            };
            let target_index: felt252 = (*target.x * 7 + *target.y).into();
            let existing = locations.get(target_index);
            assert!(existing == 0, "Location occupied");
            
            cap.location = Location::Board(*target);
            locations.insert(target_index, cap.id);
            keys.insert(cap.id.into(), NullableTrait::new(cap));
        },
        ActionType::Move(dir) => {
            let position = get_position(@cap);
            assert!(position.is_some(), "Cap not on board");
            let pos = position.unwrap();
            
            // dir.x = direction (0=right, 1=left, 2=up, 3=down)
            // dir.y = amount
            let mut new_x = pos.x;
            let mut new_y = pos.y;
            match *dir.x {
                0 => { new_x = pos.x + *dir.y; },
                1 => { new_x = pos.x - *dir.y; },
                2 => { new_y = pos.y + *dir.y; },
                3 => { new_y = pos.y - *dir.y; },
                _ => { panic!("Invalid direction"); },
            };
            
            let old_index: felt252 = (pos.x * 7 + pos.y).into();
            let new_index: felt252 = (new_x * 7 + new_y).into();
            let existing = locations.get(new_index);
            assert!(existing == 0, "Location occupied");
            
            locations.insert(old_index, 0);
            cap.location = Location::Board(Vec2 { x: new_x, y: new_y });
            locations.insert(new_index, cap.id);
            keys.insert(cap.id.into(), NullableTrait::new(cap));
        },
        ActionType::Attack(target) => {
            let position = get_position(@cap);
            assert!(position.is_some(), "Cap not on board");
            let pos = position.unwrap();
            
            // Check range (1 square for basic attack)
            assert!(is_in_range(pos, *target, 1), "Target out of range");
            
            // Get target cap
            let target_index: felt252 = (*target.x * 7 + *target.y).into();
            let target_cap_id = locations.get(target_index);
            assert!(target_cap_id != 0, "No cap at target");
            
            let mut target_cap: Cap = keys.get(target_cap_id.into()).deref();
            assert!(target_cap.owner != caller, "Cannot attack own cap");
            
            // Get attacker's CapType for attack damage
            let attacker_cap_type = get_cap_type(cap.cap_type).unwrap();
            deal_damage(ref target_cap, attacker_cap_type.attack_dmg);
            
            // If target died, remove from board
            match target_cap.location {
                Location::Dead => {
                    locations.insert(target_index, 0);
                },
                _ => {},
            };
            
            keys.insert(target_cap.id.into(), NullableTrait::new(target_cap));
        },
    };
}

// ============================================================================
// GAME STRUCT
// ============================================================================

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

// ============================================================================
// EFFECT STRUCTS (Simplified for now)
// ============================================================================

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
}

#[derive(Copy, Drop, Serde, PartialEq)]
pub enum EffectTarget {
    None,
}

// ============================================================================
// MAIN FUNCTION
// ============================================================================

pub fn main(
    game: Game,
    caps: Array<Cap>,
    effects: Array<Effect>,
    turn: Array<Action>,
) -> (Game, Array<Effect>, Array<Cap>) {
    let mut game = game;
    
    // Step 2: Process actions from turn array
    // Determine caller based on turn count
    let caller = if game.turn_count % 2 == 0 { game.player1 } else { game.player2 };
    
    // Convert caps array to dicts for processing
    let (mut locations, mut keys) = get_dicts_from_array(@caps);
    
    // Process each action in the turn
    let mut i = 0;
    while i < turn.len() {
        let action = turn.at(i);
        process_action(action, ref locations, ref keys, caller);
        i += 1;
    };
    
    // Collect cap IDs from game
    let mut cap_ids: Array<u64> = ArrayTrait::new();
    let mut j = 0;
    while j < game.caps_ids.len() {
        cap_ids.append(*game.caps_ids[j]);
        j += 1;
    };
    
    // Convert back to array
    let final_caps = caps_from_dicts(@cap_ids, ref keys);
    
    // Increment turn count
    game.turn_count = game.turn_count + 1;
    
    // Return updated game, effects (unchanged for now), and caps
    (game, effects, final_caps)
}