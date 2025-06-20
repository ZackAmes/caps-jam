use caps::models::{Vec2, Game, Cap, Action};
use starknet::ContractAddress;
// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn create_game(ref self: T, p1: ContractAddress, p2: ContractAddress) -> u64;
    fn take_turn(ref self: T, game_id: u64, turn: Array<Action>);
    fn get_game(self: @T, game_id: u64) -> Option<(Game, Span<Cap>)>;
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address};
    use caps::models::{Vec2, Game, Cap, Global, GameTrait, CapTrait, Action, ActionType};
    use caps::helpers::{get_player_pieces, get_piece_locations};

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
        pub turn: Span<Action>,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref self: ContractState, p1: ContractAddress, p2: ContractAddress) -> u64 {
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

            game_id
        }

        fn take_turn(ref self: ContractState, game_id: u64, turn: Array<Action>) {
            let mut world = self.world_default();

            let clone = turn.clone();
            let mut game: Game = world.read_model(game_id);

            let (over, _) = @game.check_over(@world);
            if *over {
                panic!("Game over");
            }

            let mut pieces = get_player_pieces(game_id, get_caller_address(), @world);

            for action in turn {
                let mut cap: Cap = world.read_model(action.cap_id);
                assert!(cap.owner == get_caller_address(), "You are not the owner of this piece");
                match action.action_type {
                    ActionType::Move(dir) => {
                        cap.move(dir.x, dir.y);
                        world.write_model(@cap);
                    },
                    ActionType::Attack(target) => {
                        let mut target_cap: Cap = world.read_model(target.x * 7 + target.y);
                        assert!(target_cap.owner != get_caller_address(), "You cannot attack your own piece");
                        game.remove_cap(target_cap.id);
                        target_cap.position = Vec2 { x: 10, y: 10 };
                        world.write_model(@target_cap);
                        world.write_model(@cap);
                        world.write_model(@game);
                    }
                }
            };

            game.turn_count = game.turn_count + 1;
            world.write_model(@game);

            world.emit_event(@Moved { player: get_caller_address(), turn: clone.span() });
        }

        fn get_game(self: @ContractState, game_id: u64) -> Option<(Game, Span<Cap>)> {
            let mut world = self.world_default();
            let game: Game = world.read_model(game_id);
            if game.player1 == starknet::contract_address_const::<0x0>(){
                return Option::None;
            }
            let caps1 = get_player_pieces(game_id, game.player1, @world);
            let caps2 = get_player_pieces(game_id, game.player2, @world);
            let mut caps = ArrayTrait::new();
            for cap in caps1 {
                caps.append(world.read_model(cap));
            };
            for cap in caps2 {
                caps.append(world.read_model(cap));
            };
            Option::Some((game, caps.span()))
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
