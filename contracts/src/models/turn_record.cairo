use caps::models::cap::{Cap, Location};
use caps::models::game::Action;
use caps::models::stack::StackEntry;

#[derive(Copy, Drop, Serde, Debug, Introspect, DojoStore)]
pub struct PieceSnapshot {
    pub id: u64,
    pub player_slot: u8,
    pub cap_type: u16,
    pub location: Location,
    pub health: u16,
    pub shield: u16,
    pub stunned_turns: u8,
    pub available_turn: u64,
}

pub fn snapshot(caps: @Array<Cap>) -> Array<PieceSnapshot> {
    let mut result = array![];
    for cap in caps.span() {
        result
            .append(
                PieceSnapshot {
                    id: *cap.id,
                    player_slot: *cap.player_slot,
                    cap_type: *cap.cap_type,
                    location: *cap.location,
                    health: *cap.health,
                    shield: *cap.shield,
                    stunned_turns: *cap.stunned_turns,
                    available_turn: *cap.available_turn,
                },
            );
    }
    result
}

/// Immutable turn journal, readable directly over RPC without an indexer.
#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct TurnRecord {
    #[key]
    pub game_id: u64,
    #[key]
    pub turn: u64,
    pub recorded: bool,
    pub player_slot: u8,
    pub actions: Array<Action>,
    pub before: Array<PieceSnapshot>,
    pub after: Array<PieceSnapshot>,
    pub stack_before: Array<StackEntry>,
    pub stack_after: Array<StackEntry>,
    /// Actual resolution order; absent entries may instead have been countered or cleared by
    /// victory.
    pub resolved: Array<StackEntry>,
    pub energy_before: u8,
    pub energy_after: u8,
}
