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

#[derive(Drop, Serde, Introspect)]
#[dojo::model]
pub struct AgentGames {
    #[key]
    id: u8,
    game_ids: Array<u128>,
}

#[derive(Drop, Serde, Introspect)]
#[dojo::model]
pub struct Player {
    #[key]
    address: ContractAddress,
    in_game: bool,
    game_id: u128,
}

#[starknet::interface]
trait IPlanetelo<T> {
    fn get_result(self: @T, session_id: u32) -> ContractAddress;
    fn play_agent(ref self: T) -> u128;
    fn settle_agent_game(ref self: T);
    fn get_agent_games(self: @T) -> Array<u128>;
    fn get_player_game_id(self: @T, address: ContractAddress) -> u128;
}

const agent_address: felt252 = 0x0694182a014b39855a1b139961a3f39e7d4b43527b30d892a630d66a2abe3780;

#[dojo::contract]
mod planetelo {
    use super::{IPlanetelo, Status, IOneOnOne, AgentGames, Player, agent_address};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
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

        fn play_agent(ref self: ContractState) -> u128 {
            let _caps_world = self.world(@"caps");
            let mut world = self.world(@"planetelo");
            let mut player: Player = world.read_model(get_caller_address());
            assert!(!player.in_game, "You are already in a game");
            let mut agent_games: AgentGames = world.read_model(0);
            let dispatcher: IActionsDispatcher = IActionsDispatcher { contract_address: world.dns_address(@"actions").unwrap() };

            let id: u128 = dispatcher.create_game(agent_address.try_into().unwrap(), get_caller_address()).into();

            agent_games.game_ids.append(id);
            world.write_model(@agent_games);
            player.in_game = true;
            player.game_id = id;
            world.write_model(@player);

            id
            
        }

        fn settle_agent_game(ref self: ContractState) {
            let caps_world = self.world(@"caps");
            let mut world = self.world(@"planetelo");
            let mut player: Player = world.read_model(get_caller_address());

            let mut new_ids: Array<u128> = ArrayTrait::new();
            let mut found = false;

            let mut agent_games: AgentGames = caps_world.read_model(0);
            let mut i = 0;
            while i < agent_games.game_ids.len() {
                let game_id = agent_games.game_ids.at(i);
                let game: Game = caps_world.read_model(*game_id);
                if game.player2 == get_caller_address() {
                    let (over, winner) = @game.check_over(@caps_world);
                    if *over {
                        found = true;
                        continue;
                    }
                    else{ 
                        panic!("Game is not over");
                    }
                }
                else{
                    new_ids.append(*game_id);
                }
                i += 1;
            };

            if found {
                agent_games.game_ids = new_ids;
                world.write_model(@agent_games);
                player.in_game = false;
                player.game_id = 0;
                world.write_model(@player);
            }
            else{
                panic!("Game not found");
            }
        }

        fn get_agent_games(self: @ContractState) -> Array<u128> {
            let mut world = self.world(@"planetelo");
            let mut agent_games: AgentGames = world.read_model(0);
            agent_games.game_ids
        }

        fn get_player_game_id(self: @ContractState, address: ContractAddress) -> u128 {
            let mut world = self.world(@"planetelo");
            let mut player: Player = world.read_model(address);
            player.game_id
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


