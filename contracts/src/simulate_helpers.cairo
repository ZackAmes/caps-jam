use caps::models::effect::{Effect, EffectType, Timing, EffectTrait};
use caps::models::game::{Game, GameTrait};

pub fn get_active_effects_from_array(game: @Game, effects: @Array<Effect>) -> (Array<Effect>, Array<Effect>, Array<Effect>) {
    let mut start_of_turn_effects: Array<Effect> = ArrayTrait::new();
    let mut move_step_effects: Array<Effect> = ArrayTrait::new();
    let mut end_of_turn_effects: Array<Effect> = ArrayTrait::new();

    let mut i = 0;
    while i < effects.len() {
        let effect = *effects.at(i);
        match effect.get_timing() {
            Timing::StartOfTurn => {
                start_of_turn_effects.append(effect);
            },
            Timing::MoveStep => {
                move_step_effects.append(effect);
            },
            Timing::EndOfTurn => {
                end_of_turn_effects.append(effect);
            },
            _ => {}
        }
        i += 1;
    };

    (start_of_turn_effects, move_step_effects, end_of_turn_effects)
}