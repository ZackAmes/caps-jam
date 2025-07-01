#[cfg(test)]
mod tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };

    use caps::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use caps::models::cap::{Cap, m_Cap, CapType, m_CapType, TargetType};
    use caps::models::effect::{Effect, m_Effect, EffectType, EffectTarget, Timing};
    use caps::models::game::{Vec2, Game, m_Game, Action, ActionType, Global, m_Global};
    use caps::models::set::{Set, m_Set, ISetInterface};
    use caps::sets::set_zero::{set_zero};

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "caps",
            resources: [
                TestResource::Model(m_Cap::TEST_CLASS_HASH),
                TestResource::Model(m_CapType::TEST_CLASS_HASH),
                TestResource::Model(m_Effect::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_Global::TEST_CLASS_HASH),
                TestResource::Model(m_Set::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
                TestResource::Contract(set_zero::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"caps", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"caps")].span()),
            ContractDefTrait::new(@"caps", @"set_zero")
                .with_writer_of([dojo::utils::bytearray_hash(@"caps")].span()),
        ]
            .span()
    }

    #[test]
    fn test_world_test_set() {
        // Initialize test environment
        let caller = starknet::contract_address_const::<0x0>();
        let ndef = namespace_def();

        // Register the resources.
        let mut world = spawn_test_world([ndef].span());

        // Ensures permissions and initializations are synced.
        world.sync_perms_and_inits(contract_defs());

    }

    #[test]
    #[available_gas(30000000)]
    fn test_move() {
        let caller = starknet::contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"actions").unwrap();
        let actions_system = IActionsDispatcher { contract_address };


    }
}
