use caps::models::cap::{Cap, CapType};
use caps::models::effect::Effect;
use caps::models::game::{Vec2, Game};
use caps::conversions::{
    caps_array_into_core, caps_array_from_core, effects_array_from_core,
    GameIntoCore, GameFromCore, CapIntoCore, CapFromCore, TargetTypeFromCore,
};
use core::dict::{Felt252Dict, Felt252DictTrait};

// Helper function to convert core Vec2 array to contract Vec2 array
fn vec2_array_from_core(arr: Array<caps_core::types::game::Vec2>) -> Array<Vec2> {
    let mut result = ArrayTrait::new();
    for v in arr {
        result.append(Vec2 { x: v.x, y: v.y });
    }
    result
}

#[dojo::contract]
pub mod set_zero {
    use caps::models::set::{ISetInterface, Set};
    use caps::models::cap::{Cap, CapType};
    use caps::models::game::{Game, Vec2};
    use caps::models::effect::Effect;
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage};
    use caps_core::logic::helpers::get_dicts_from_array;
    use super::{
        caps_array_into_core, caps_array_from_core, effects_array_from_core, vec2_array_from_core,
    };
    use caps::conversions::{TargetTypeFromCore, CapIntoCore};

    fn dojo_init(ref self: ContractState) {
        let mut world: WorldStorage = self.world(@"caps");
        let set = Set { id: 0, address: world.dns_address(@"set_zero").unwrap() };
        world.write_model(@set);
    }

    #[abi(embed_v0)]
    impl SetZeroImpl of ISetInterface<ContractState> {
        fn get_cap_type(self: @ContractState, id: u16) -> Option<CapType> {
            // Convert core CapType to contract CapType
            match caps_core::sets::set_zero::get_cap_type(id) {
                Option::Some(core_cap_type) => {
                    // Since CapType has the same structure, we can reconstruct it
                    Option::Some(
                        CapType {
                            id: core_cap_type.id,
                            name: core_cap_type.name,
                            description: core_cap_type.description,
                            play_cost: core_cap_type.play_cost,
                            move_cost: core_cap_type.move_cost,
                            attack_cost: core_cap_type.attack_cost,
                            attack_range: vec2_array_from_core(core_cap_type.attack_range),
                            ability_range: vec2_array_from_core(core_cap_type.ability_range),
                            ability_description: core_cap_type.ability_description,
                            move_range: Vec2 { x: core_cap_type.move_range.x, y: core_cap_type.move_range.y },
                            attack_dmg: core_cap_type.attack_dmg,
                            base_health: core_cap_type.base_health,
                            ability_target: core_cap_type.ability_target.into(),
                            ability_cost: core_cap_type.ability_cost,
                        },
                    )
                },
                Option::None => Option::None,
            }
        }

        fn activate_ability(
            ref self: ContractState, cap: Cap, target: Vec2, game: Game, caps: Array<Cap>,
        ) -> (Game, Array<Effect>, Array<Cap>) {
            // Convert contract types to core types using helper functions
            let core_caps = caps_array_into_core(caps);
            let temp_cap_array = caps_array_into_core(array![cap]);
            let mut core_cap = *temp_cap_array[0];
            let core_target: caps_core::types::game::Vec2 = caps_core::types::game::Vec2 { x: target.x, y: target.y };
            let mut core_game: caps_core::types::game::Game = caps_core::types::game::Game {
                id: game.id,
                player1: game.player1,
                player2: game.player2,
                caps_ids: game.caps_ids,
                turn_count: game.turn_count,
                over: game.over,
                effect_ids: game.effect_ids,
                last_action_timestamp: game.last_action_timestamp,
            };
            
            // Get cap type from core
            let mut core_cap_type = caps_core::sets::set_zero::get_cap_type(core_cap.cap_type)
                .unwrap();
            
            // Get dictionaries from array
            let (mut locations, mut keys) = get_dicts_from_array(@core_caps);
            
            // Call core use_ability
            let (result_game, result_effects, result_caps) = caps_core::sets::set_zero::use_ability(
                ref core_cap, ref core_cap_type, core_target, ref core_game, ref locations, ref keys,
            );
            
            // Convert results back to contract types
            let contract_game: Game = Game {
                id: result_game.id,
                player1: result_game.player1,
                player2: result_game.player2,
                caps_ids: result_game.caps_ids,
                turn_count: result_game.turn_count,
                over: result_game.over,
                effect_ids: result_game.effect_ids,
                last_action_timestamp: result_game.last_action_timestamp,
            };
            let contract_effects = effects_array_from_core(result_effects);
            let contract_caps = caps_array_from_core(result_caps);
            
            (contract_game, contract_effects, contract_caps)
        }
    }
}
