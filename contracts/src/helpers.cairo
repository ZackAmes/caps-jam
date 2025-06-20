
use dojo::model::{ModelStorage};
use caps::models::{Game, Cap};
use starknet::ContractAddress;
use dojo::world::WorldStorage;
use core::dict::Felt252Dict;


pub fn get_player_pieces(game_id: u64, player: ContractAddress, world: @WorldStorage) -> Array<u64> {
    let mut game: Game = world.read_model(game_id);
    let mut pieces: Array<u64> = ArrayTrait::new();
    let mut i = 0;

    assert!(game.player1 == player || game.player2 == player, "Not in game");

    while i < game.caps_ids.len() {
        let cap: Cap = world.read_model(*game.caps_ids[i]);
        if cap.owner == player {
            pieces.append(cap.id);
        }
        i += 1;
    };

    pieces
}

pub fn get_piece_locations(game_id: u64, world: @WorldStorage) -> Felt252Dict<u64> {
    let mut game: Game = world.read_model(game_id);
    let mut locations: Felt252Dict<u64> = Default::default();

    let mut i = 0;

    while i < game.caps_ids.len() {
        let cap: Cap = world.read_model(*game.caps_ids[i]);
        let index = cap.position.x * 7 + cap.position.y;
        locations.insert(index.into(), cap.id);
        i += 1;
    };

    locations
}