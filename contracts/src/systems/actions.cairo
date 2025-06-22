use caps::models::{Vec2, Game, Cap, Action, CapType, Effect, EffectType};
use starknet::ContractAddress;
// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn create_game(ref self: T, p1: ContractAddress, p2: ContractAddress) -> u64;
    fn take_turn(ref self: T, game_id: u64, turn: Array<Action>);
    fn get_game(self: @T, game_id: u64) -> Option<(Game, Span<Cap>)>;
    fn get_cap_data(self: @T, cap_type: u16) -> Option<CapType>;
}


// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address};
    use caps::models::{Vec2, Game, Cap, Global, GameTrait, CapTrait, Action, ActionType, CapType, TargetType, TargetTypeTrait, Effect, EffectType};
    use caps::helpers::{get_player_pieces, get_piece_locations, get_active_effects};
    use core::dict::{Felt252DictTrait, SquashedFelt252Dict};

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct Moved {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u64,
        #[key]
        pub turn_number: u64,
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
                over: false,
                active_start_of_turn_effects: ArrayTrait::new(),
                active_damage_step_effects: ArrayTrait::new(),
                active_move_step_effects: ArrayTrait::new(),
                active_end_of_turn_effects: ArrayTrait::new(),
            };

            let p1_cap1 = Cap {
                id: global.cap_counter + 1,
                owner: p1,
                position: Vec2 { x: 2, y: 0 },
                cap_type: 0,
                dmg_taken: 0,
            };
            let p1_cap2 = Cap {
                id: global.cap_counter + 2,
                owner: p1,
                position: Vec2 { x: 4, y: 0 },
                cap_type: 4,
                dmg_taken: 0,
            };

            let p1_cap3 = Cap {
                id: global.cap_counter + 3,
                owner: p2,
                position: Vec2 { x: 3, y: 6 },
                cap_type: 8,
                dmg_taken: 0,
            };

            let p2_cap1 = Cap {
                id: global.cap_counter + 3,
                owner: p2,
                position: Vec2 { x: 2, y: 6 },
                cap_type: 1,
                dmg_taken: 0,
            };

            let p2_cap2 = Cap {
                id: global.cap_counter + 4,
                owner: p2,
                position: Vec2 { x: 4, y: 6 },
                cap_type: 5,
                dmg_taken: 0,
            };

            

            let p2_cap3 = Cap {
                id: global.cap_counter + 4,
                owner: p2,
                position: Vec2 { x: 3, y: 6 },
                cap_type: 9,
                dmg_taken: 0,
            };

            game.add_cap(p1_cap1.id);
            game.add_cap(p1_cap2.id);
            game.add_cap(p1_cap3.id);
            game.add_cap(p2_cap1.id);
            game.add_cap(p2_cap2.id);
            game.add_cap(p2_cap3.id);

            global.cap_counter = global.cap_counter + 4;

            world.write_model(@game);
            world.write_model(@p1_cap1);
            world.write_model(@p1_cap2);
            world.write_model(@p1_cap3);
            world.write_model(@p2_cap1);
            world.write_model(@p2_cap2);
            world.write_model(@p2_cap3);

            game_id
        }

        fn take_turn(ref self: ContractState, game_id: u64, turn: Array<Action>) {
            let mut world = self.world_default();

            let clone = turn.clone();
            let mut game: Game = world.read_model(game_id);

            let (over, _) = @game.check_over(@world);
            if *over {
                panic!("Game is over");
            }

            let (start_of_turn_effects, damage_step_effects, move_step_effects, end_of_turn_effects) = get_active_effects(game_id, @world);

            let mut extra_energy: u8 = 0;
            let mut i = 0;
            while i < start_of_turn_effects.len() {
                let effect: Effect = *start_of_turn_effects.at(i);
                match effect.effect_type {
                    EffectType::ExtraEnergy(x) => {
                        extra_energy += x;
                    },
                    _ => {
                        continue;
                    }
                }
                i += 1;
            };

            let mut energy: u8 = game.turn_count.try_into().unwrap() + 2 + extra_energy;

            while i < turn.len() {
                let action = turn.at(i);
                let mut locations = get_piece_locations(game_id, @world);
                let mut cap: Cap = world.read_model(*action.cap_id);
                assert!(cap.owner == get_caller_address(), "You are not the owner of this piece");
                let cap_type = self.get_cap_data(cap.cap_type).unwrap();
                let mut move_discount: (u8, Array<u64>) = (0, ArrayTrait::new());
                let mut attack_discount: (u8, Array<u64>) = (0, ArrayTrait::new());
                let mut ability_discount: (u8, Array<u64>) = (0, ArrayTrait::new());
                let mut stun: (bool, Array<u64>) = (false, ArrayTrait::new());
                let mut double: (bool, Array<u64>) = (false, ArrayTrait::new());
                let mut attack_bonus: (u8, Array<u64>) = (0, ArrayTrait::new());
                let mut bonus_range: (u8, Array<u64>) = (0, ArrayTrait::new());

                let mut index = 0;
                while index < move_step_effects.len() {
                    let effect: Effect = *move_step_effects.at(index);

                    match effect.effect_type {
                        EffectType::Double => {
                            double = (true, array![effect.effect_id]);
                        },
                        EffectType::MoveDiscount(x) => {
                            let (discount, mut ids) = move_discount;
                            ids.append(effect.effect_id);
                            move_discount = (discount + x, ids);
                        },
                        EffectType::AttackDiscount(x) => {
                            let (discount, mut ids) = attack_discount;
                            ids.append(effect.effect_id);
                            attack_discount = (discount + x, ids);
                        },
                        EffectType::AbilityDiscount(x) => {
                            let (discount, mut ids) = ability_discount;
                            ids.append(effect.effect_id);
                            ability_discount = (discount + x, ids);
                        },   
                        EffectType::Stun => {
                            stun = (true, array![effect.effect_id]);
                        },
                        EffectType::AttackBonus(x) => {
                            let (bonus, mut ids) = attack_bonus;
                            ids.append(effect.effect_id);
                            attack_bonus = (bonus + x, ids);
                        },
                        EffectType::BonusRange(x) => {
                            let (range, mut ids) = bonus_range;
                            ids.append(effect.effect_id);
                            bonus_range = (range + x, ids);
                        },
                        _ => {
                            continue;
                        }
                    }
                    index += 1;
                };

                match action.action_type {
                    ActionType::Move(dir) => {
                        assert!(energy >= cap_type.move_cost, "Not enough energy");
                        energy -= cap_type.move_cost;
                        let new_location_index = cap.get_new_index_from_dir(*dir.x, *dir.y);
                        let piece_at_location_id = locations.get(new_location_index.into());
                        assert!(piece_at_location_id == 0, "There is a piece at the new location");
                        cap.move(cap_type, *dir.x, *dir.y);
                        world.write_model(@cap);
                    },
                    ActionType::Attack(target) => {
                        assert!(energy >= cap_type.attack_cost, "Not enough energy");
                        energy -= cap_type.attack_cost;
                        let piece_at_location_id = locations.get((*target.x * 7 + *target.y).into());
                        let mut piece_at_location: Cap = world.read_model(piece_at_location_id);
                        let piece_at_location_type = self.get_cap_data(piece_at_location.cap_type).unwrap();
                        assert!(piece_at_location_id != 0, "There is no piece at the target location");
                        assert!(piece_at_location.owner != get_caller_address(), "You cannot attack your own piece");
                        if(!cap.check_in_range(*target, cap_type.attack_range)) {
                            panic!("Attack is not valid");
                        }
                        piece_at_location.dmg_taken += cap_type.attack_dmg;
                        if piece_at_location.dmg_taken >= piece_at_location_type.base_health {
                            game.remove_cap(piece_at_location.id);
                            world.erase_model(@piece_at_location);
                        }
                        else {
                            world.write_model(@piece_at_location);
                        }
                        world.write_model(@cap);
                        world.write_model(@game);
                    },
                    ActionType::Ability(target) => {
                        let cap_type = self.get_cap_data(cap.cap_type).unwrap();
                        let cap_type_2 = self.get_cap_data(cap.cap_type).unwrap();
                        assert!(cap_type.ability_target != TargetType::None, "Ability should not be none");
                        assert!(cap_type.ability_target.is_valid(@cap, cap_type_2, *target, game_id, @world), "Ability is not valid");
                        cap.use_ability(cap_type, *target, game_id, ref world);
                    }
                }
                i = i + 1;
            };

            game.turn_count = game.turn_count + 1;
            let (over, _) = @game.check_over(@world);
            game.over = *over;
            world.write_model(@game);

            world.emit_event(@Moved { player: get_caller_address(), game_id: game_id, turn_number: game.turn_count-1, turn: clone.span() });
        }

        fn get_game(self: @ContractState, game_id: u64) -> Option<(Game, Span<Cap>)> {
            let mut world = self.world_default();
            let game: Game = world.read_model(game_id);
            if game.player1 == starknet::contract_address_const::<0x0>(){
                return Option::None;
            }
            let mut i = 0;
            let mut caps: Array<Cap> = ArrayTrait::new();
            while i < game.caps_ids.len(){
                let cap: Cap = world.read_model(*game.caps_ids[i]);
                caps.append(cap);
                i += 1;
            };
            Option::Some((game, caps.span()))
        }

        fn get_cap_data(self: @ContractState, cap_type: u16) -> Option<CapType> {
            let mut world = self.world_default();
            let res = match cap_type {
                0 => Option::Some(CapType {
                    id: 0,
                    name: "Red Tower",
                    description: "Red Tower",
                    move_cost: 1,
                    attack_cost: 1,
                    attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
                    ability_range: array![],
                    ability_description: "None",
                    move_range: Vec2 { x: 1, y: 1 },
                    attack_dmg: 1,
                    base_health: 10,
                    ability_target: TargetType::None,
                    ability_cost: 0,
                }),
                1 => Option::Some(CapType {
                    id: 1,
                    name: "Blue Tower",
                    description: "Blue Tower",
                    move_cost: 1,
                    attack_cost: 1,
                    attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
                    ability_range: array![],
                    ability_description: "None",
                    move_range: Vec2 { x: 1, y: 1 },
                    attack_dmg: 1,
                    base_health: 10,
                    ability_target: TargetType::None,
                    ability_cost: 0,
                }),
                2 => Option::Some(CapType {
                    id: 2,
                    name: "Yellow Tower",
                    description: "Yellow Tower",
                    move_cost: 1,
                    attack_cost: 1,
                    attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
                    ability_range: array![],
                    ability_description: "None",
                    move_range: Vec2 { x: 1, y: 1 },
                    attack_dmg: 1,
                    base_health: 10,
                    ability_target: TargetType::None,
                    ability_cost: 0,
                }),
                3 => Option::Some(CapType {
                    id: 3,
                    name: "Green Tower",
                    description: "Green Tower",
                    move_cost: 1,
                    attack_cost: 1,
                    attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
                    ability_range: array![],
                    ability_description: "None",
                    move_range: Vec2 { x: 1, y: 1 },
                    attack_dmg: 1,
                    base_health: 10,
                    ability_target: TargetType::None,
                    ability_cost: 0,
                }),
                4 => Option::Some(CapType {
                    id: 4,
                    name: "Red Basic",
                    description: "Cap 3",
                    move_cost: 1,
                    attack_cost: 2,
                    attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
                    ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
                    ability_description: "Deal 5 damage to an enemy",
                    move_range: Vec2 { x: 2, y: 2 },
                    attack_dmg: 4,
                    base_health: 5,
                    ability_target: TargetType::OpponentCap,
                    ability_cost: 3,
                }),
                5 => Option::Some(CapType {
                    id: 5,
                    name: "Blue Basic",
                    description: "Cap 4",
                    move_cost: 1,
                    attack_cost: 2,
                    attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
                    ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
                    ability_description: "Heal 5 damage from an ally",
                    move_range: Vec2 { x: 3, y: 3 },
                    attack_dmg: 3,
                    base_health: 6,
                    ability_target: TargetType::TeamCap,
                    ability_cost: 2,
                }),
                6 => Option::Some(CapType {
                    id: 6,
                    name: "Yellow Basic",
                    description: "Cap 5",
                    move_cost: 1,
                    attack_cost: 3,
                    attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
                    ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
                    ability_description: "Heal 5 damage from an ally",
                    move_range: Vec2 { x: 3, y: 3 },
                    attack_dmg: 3,
                    base_health: 6,
                    ability_target: TargetType::TeamCap,
                    ability_cost: 2,
                }),
                7 => Option::Some(CapType {
                    id: 7,
                    name: "Green Basic",
                    description: "Cap 6",
                    move_cost: 1,
                    attack_cost: 3,
                    attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
                    ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
                    ability_description: "Heal 5 damage from an ally",
                    move_range: Vec2 { x: 3, y: 3 },
                    attack_dmg: 3,
                    base_health: 6,
                    ability_target: TargetType::TeamCap,
                    ability_cost: 2,

                }),
                8 => Option::Some(CapType {
                    id: 8,
                    name: "Red Elite",
                    description: "Cap 8",
                    move_cost: 1,
                    attack_cost: 2,
                    attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
                    ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
                    ability_description: "Deal 5 damage to an enemy",
                    move_range: Vec2 { x: 2, y: 2 },
                    attack_dmg: 4,
                    base_health: 5,
                    ability_target: TargetType::OpponentCap,
                    ability_cost: 3,
                }),
                9 => Option::Some(CapType {
                    id: 9,
                    name: "Blue Elite",
                    description: "Cap 9",
                    move_cost: 1,
                    attack_cost: 2,
                    attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
                    ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
                    ability_description: "Heal 5 damage from an ally",
                    move_range: Vec2 { x: 3, y: 3 },
                    attack_dmg: 3,
                    base_health: 6,
                    ability_target: TargetType::TeamCap,
                    ability_cost: 2,
                }),
                10 => Option::Some(CapType {
                    id: 10,
                    name: "Yellow Elite",
                    description: "Cap 10",
                    move_cost: 1,
                    attack_cost: 3,
                    attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
                    ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
                    ability_description: "Heal 5 damage from an ally",
                    move_range: Vec2 { x: 3, y: 3 },
                    attack_dmg: 3,
                    base_health: 6,
                    ability_target: TargetType::TeamCap,
                    ability_cost: 2,
                }),
                11 => Option::Some(CapType {
                    id: 11,
                    name: "Green Elite",
                    description: "Cap 11",
                    move_cost: 1,
                    attack_cost: 3,
                    attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
                    ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
                    ability_description: "Heal 5 damage from an ally",
                    move_range: Vec2 { x: 3, y: 3 },
                    attack_dmg: 3,
                    base_health: 6,
                    ability_target: TargetType::TeamCap,
                    ability_cost: 2,
                }),
                _ => Option::None,
            };
            res
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
