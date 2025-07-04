use starknet::ContractAddress;
use caps::models::cap::CapType;
use caps::models::cap::Cap;
use caps::models::game::{Game, Vec2};
use caps::models::effect::Effect;
#[derive(Drop, Copy, Serde, Introspect)]
#[dojo::model]
pub struct Set {
    #[key]
    pub id: u64,
    pub address: ContractAddress,
}


#[starknet::interface]
pub trait ISetInterface<T> {
    fn get_cap_type(self: @T, id: u16) -> Option<CapType>;
    fn activate_ability(
        ref self: T, cap: Cap, target: Vec2, game: Game, caps: Array<Cap>,
    ) -> (Game, Array<Effect>, Array<Cap>);
}
