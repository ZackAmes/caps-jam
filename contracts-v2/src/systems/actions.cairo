use dojo_starter::models::{Direction};

// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn submit_move(ref self: T, game_id: u64, hash: felt252);
    fn reveal_moves(ref self: T, game_id: u64, player_1_moves: Array<Action>, player_2_moves: Array<Action>);
    fn get_game(self: @T, game_id: u64) -> Option<(Game, Span<Cap>)>;
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use dojo::event::EventStorage;
    use dojo::model::ModelStorage;
    use dojo_starter::models::{Moves, Vec2};
    use starknet::{ContractAddress, get_caller_address};
    use super::{Direction, IActions, Position, next_position};


    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
       

    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"caps")
        }
    }
}
