use caps::models::{Vec2};
use starknet::ContractAddress;
// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn create_game(ref self: T, p1: ContractAddress, p2: ContractAddress);
    fn take_turn(ref self: T, game_id: u64, turn: Vec2);
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address};
    use caps::models::{Vec2, Game, Cap, Global, GameTrait, CapTrait};
    use caps::helpers::get_player_pieces;

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;

    #[storage]
    struct Storage {
        games_counter: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Moved {
        #[key]
        pub player: ContractAddress,
        pub turn: Vec2,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref self: ContractState, p1: ContractAddress, p2: ContractAddress) {
            // Get the default world.
            let mut world = self.world_default();

            let mut global: Global = world.read_model(0);

            let game_id = global.games_counter + 1;
            global.games_counter = game_id;
            world.write_model(@global);

            let mut game = Game {
                id: game_id,
                player1: p1,
                player2: p2,
                caps_ids: ArrayTrait::new(),
                turn_count: 0,
            };

            let p1_cap = Cap {
                id: global.cap_counter + 1,
                owner: p1,
                position: Vec2 { x: 3, y: 0 },
            };

            let p2_cap = Cap {
                id: global.cap_counter + 2,
                owner: p2,
                position: Vec2 { x: 3, y: 6 },
            };

            game.add_cap(p1_cap.id);
            game.add_cap(p2_cap.id);

            global.cap_counter = global.cap_counter + 2;

            world.write_model(@game);
            world.write_model(@p1_cap);
            world.write_model(@p2_cap);
        }

        fn take_turn(ref self: ContractState, game_id: u64, turn: Vec2) {
            let mut world = self.world_default();

            let mut game: Game = world.read_model(game_id);

            let (over, _) = @game.check_over(@world);
            if *over {
                panic!("Game over");
            }

            let mut pieces = get_player_pieces(game_id, get_caller_address(), @world);

            let mut cap: Cap = world.read_model(*pieces[0]);
            cap.move(turn);
            world.write_model(@cap);
            game.turn_count = game.turn_count + 1;
            world.write_model(@game);

            world.emit_event(@Moved { player: get_caller_address(), turn });
        }

    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"caps")
        }
    }
}
