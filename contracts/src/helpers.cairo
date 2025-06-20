
use dojo::model::{ModelStorage};
use caps::models::{Game, Cap};
use starknet::ContractAddress;
use dojo::world::WorldStorage;

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