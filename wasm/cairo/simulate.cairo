pub fn main(
    self: @ContractState,
    game: Game,
    caps: Array<Cap>,
    effects: Option<Array<Effect>>,
    turn: Array<Action>,
) -> (Game, Span<Effect>, Span<Cap>) {
    //the only world read is for the set. This is just for convenience and shouldn't be too
    //hard to remove when neccesary we still need to figure out how to handle the sets when
    //running in wasm anyways
    let mut world = self.world(@"caps");
    let mut set = world.read_model(*caps[0].set_id);
    let mut effects = effects.unwrap_or(ArrayTrait::new());
    let mut game = game;
    let mut turn = turn;

    let (mut start_of_turn_effects, mut move_step_effects, mut end_of_turn_effects) =
        get_active_effects_from_array(
        @game, @effects,
    );

    let mut caller = starknet::contract_address_const::<0x0>();

    if game.turn_count % 2 == 0 {
        caller = game.player1;
    } else {
        caller = game.player2;
    }

    let (mut locations, mut keys) = get_dicts_from_array(@caps);

    let (
        new_game,
        new_locations,
        new_keys,
        new_start_of_turn_effects,
        new_move_step_effects,
        new_end_of_turn_effects,
    ) =
        process_actions(
        ref game,
        ref turn,
        ref locations,
        ref keys,
        ref start_of_turn_effects,
        ref move_step_effects,
        ref end_of_turn_effects,
        ref set,
        caller,
    );

    game = new_game;
    locations = new_locations;
    keys = new_keys;
    move_step_effects = new_move_step_effects;
    end_of_turn_effects = new_end_of_turn_effects;

    let (mut game, mut new_end_of_turn_effects, new_locations, new_keys) =
        update_end_of_turn_effects(
        ref game, ref end_of_turn_effects, ref locations, ref keys,
    );

    end_of_turn_effects = new_end_of_turn_effects;
    locations = new_locations;
    keys = new_keys;

    let mut final_caps: Array<Cap> = ArrayTrait::new();
    let mut i = 0;
    let mut one_found = false;
    let mut two_found = false;
    let mut one_tower_found = false;
    let mut two_tower_found = false;
    while i < game.caps_ids.len() {
        let cap_id = *game.caps_ids[i];
        let cap = keys.get(cap_id.into()).deref();
        let cap_type = self.get_cap_data(cap.set_id, cap.cap_type).unwrap();
        if cap.dmg_taken >= cap_type.base_health {
            game.remove_cap(cap_id);
        } else {
            if cap.owner == (game.player1).into() {
                //todo: better way to tell if it's a tower
                if cap.cap_type < 4 {
                    one_tower_found = true;
                }
                one_found = true;
            } else if cap.owner == (game.player2).into() {
                if cap.cap_type < 4 {
                    two_tower_found = true;
                }
                two_found = true;
            }
            final_caps.append(cap);
        }
        i += 1;
    };

    if !one_found || !one_tower_found {
        game.over = true;
    }
    if !two_found || !two_tower_found {
        game.over = true;
    }
    let mut final_effects: Array<Effect> = ArrayTrait::new();
    let mut new_effect_ids: Array<u64> = ArrayTrait::new();
    for effect in new_start_of_turn_effects {
        if effect.remaining_triggers > 0 {
            new_effect_ids.append(effect.effect_id);
            final_effects.append(effect);
        }
    };
    for effect in move_step_effects {
        if effect.remaining_triggers > 0 {
            new_effect_ids.append(effect.effect_id);
            final_effects.append(effect);
        }
    };
    for effect in end_of_turn_effects {
        if effect.remaining_triggers > 0 {
            new_effect_ids.append(effect.effect_id);
            final_effects.append(effect);
        }
    };

    game.last_action_timestamp = get_block_timestamp();
    game.turn_count = game.turn_count + 1;
    game.effect_ids = new_effect_ids;

    (game, final_effects.span(), final_caps.span())
}