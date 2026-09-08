use caps::models::effect::Relation;
use caps::models::game::Vec2;

#[derive(Copy, Drop, Serde, Debug, Introspect, DojoStore)]
pub enum ImpactKind {
    Damage,
    Heal,
    Shield,
}
impl ImpactKindDefault of Default<ImpactKind> {
    fn default() -> ImpactKind {
        ImpactKind::Damage
    }
}
#[derive(Copy, Drop, Serde, Debug, Introspect, DojoStore)]
pub struct Zone {
    pub center: Vec2,
    pub radius: u8,
}
#[derive(Copy, Drop, Serde, Debug, Introspect, DojoStore)]
pub enum Selection {
    Piece: u64,
    Row: u8,
    Column: u8,
    Within: Zone,
}
impl SelectionDefault of Default<Selection> {
    fn default() -> Selection {
        Selection::Row(0)
    }
}

/// Immutable announcement. Selection is evaluated on the board at resolution.
#[derive(Copy, Drop, Serde, Debug, Introspect, DojoStore)]
pub struct DelayedImpact {
    pub kind: ImpactKind,
    pub selection: Selection,
    pub relation: Relation,
    pub amount: u16,
}
#[derive(Copy, Drop, Serde, Debug, Introspect, DojoStore)]
pub struct Schedule {
    /// Complete future player turns granted before the effect becomes ready (1..8).
    pub delay: u8,
    pub impact: DelayedImpact,
}
#[derive(Copy, Drop, Serde, Debug, Introspect, DojoStore)]
pub struct StackEntry {
    pub id: u64,
    pub source_id: u64,
    pub player_slot: u8,
    pub announced_turn: u64,
    /// Earliest turn boundary. A newer unready entry blocks older ready entries.
    pub ready_turn: u64,
    pub impact: DelayedImpact,
}
#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct AbilityStack {
    #[key]
    pub game_id: u64,
    pub next_id: u64,
    /// Oldest first; last entry is the top.
    pub entries: Array<StackEntry>,
}
