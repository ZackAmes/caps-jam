#[derive(Drop, Copy, Serde, Introspect)]
#[dojo::model]
pub struct Cap {
    #[key]
    pub id: u64,
    pub owner: felt252,
    pub location: Location,
    pub dmg_taken: u16,
}
