use starknet::ContractAddress;

//planetelo 1on1 interface
#[starknet::interface]
pub trait IOneOnOne<TState> {
    fn create_match(ref self: TState, p1: ContractAddress, p2: ContractAddress, playlist_id: u128) -> u128;
    fn settle_match(ref self: TState, match_id: u128) -> Status;
}

#[derive(Drop, Serde)]
pub enum Status {
    None,
    Active,
    Draw,
    Winner: ContractAddress,
}

#[starknet::interface]
trait IPlanetelo<T> {
    fn get_result(self: @T, session_id: u32) -> ContractAddress;
}

#[dojo::contract]
mod planetelo {
    use super::{IPlanetelo, Status, IOneOnOne};
    use starknet::{ContractAddress, get_block_timestamp};
    use dojo::world::{WorldStorage, WorldStorageTrait};    
    use dojo::model::{ModelStorage};

    use caps::models::{Game, GameTrait};
    use caps::systems::actions::{IActionsDispatcher, IActionsDispatcherTrait};


    #[abi(embed_v0)]
    impl PlaneteloInterfaceImpl of IPlanetelo<ContractState> {

        fn get_result(self: @ContractState, session_id: u32) -> ContractAddress {
            let mut world = self.world(@"caps");
            let game: Game = world.read_model(session_id);
            let (over, winner) = @game.check_over(@world);
            if *over {
                return *winner;
            }
            return starknet::contract_address_const::<0>();
        }
    }

    #[abi(embed_v0)]
    impl OneOnOneImpl of IOneOnOne<ContractState> {
        fn create_match(ref self: ContractState, p1: ContractAddress, p2: ContractAddress, playlist_id: u128) -> u128{

            let mut world = self.world(@"caps");
            let dispatcher: IActionsDispatcher = IActionsDispatcher { contract_address: world.dns_address(@"actions").unwrap() };

            let id: u128 = dispatcher.create_game(p1, p2).into();
            id
        }

        fn settle_match(ref self: ContractState, match_id: u128) -> Status {
            let mut world = self.world(@"caps");
            let game: Game = world.read_model(match_id);
            let (over, winner) = @game.check_over(@world);

            if !*over {
                return Status::Active;
            }
            else {
                if *winner == game.player1 {
                    return Status::Winner(game.player1);
                }
                else if *winner == game.player2 {
                    return Status::Winner(game.player2);
                }
                else {
                    return Status::None;
                }
            }

        }
    }
}


