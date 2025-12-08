// ============================================================================
// SIMPLIFIED SIMULATE - Single action with Felt252Dict
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
    pub cap_type: u16,
    pub health: u16,
    pub dmg_taken: u16,
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
    };
}

// ============================================================================
// MAIN FUNCTION
// ============================================================================

pub fn main(
    caps: Array<Cap>,
    action: Action,
    caller: felt252,
) -> Array<Cap> {
    let (mut locations, mut keys) = get_dicts_from_array(@caps);
    
    // Collect cap IDs before processing
    let mut cap_ids: Array<u64> = ArrayTrait::new();
    let mut i = 0;
    while i < caps.len() {
        cap_ids.append(*caps.at(i).id);
        i += 1;
    };
    
    process_action(@action, ref locations, ref keys, caller);
    
    caps_from_dicts(@cap_ids, ref keys)
}
