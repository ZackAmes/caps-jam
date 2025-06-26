#[derive(Drop, Copy, Serde, Introspect)]
#[dojo::model]
pub struct Set {
    #[key]
    pub id: u64,
    pub address: ContractAddress,
}
