use caps::models::{Vec2, Game, Cap, Action, CapType, Effect, EffectType};
use starknet::ContractAddress;
// define the interface
#[starknet::interface]
pub trait IActions<T> {
    fn create_game(ref self: T, p1: ContractAddress, p2: ContractAddress, p1_team: u16, p2_team: u16) -> u64;
    fn take_turn(ref self: T, game_id: u64, turn: Array<Action>);
    fn get_game(self: @T, game_id: u64) -> Option<(Game, Span<Cap>, Span<Effect>)>;
    fn get_cap_data(self: @T, cap_type: u16) -> Option<CapType>;
}


// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address};
    use caps::models::{Vec2, Game, Cap, Global, GameTrait, CapTrait, Action, ActionType, CapType, TargetType, TargetTypeTrait, Effect, EffectType, EffectTarget, get_cap_type, handle_damage};
    use caps::helpers::{get_player_pieces, get_piece_locations, get_active_effects, update_move_step_effects, update_end_of_turn_effects, update_start_of_turn_effects};
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
        fn create_game(ref self: ContractState, p1: ContractAddress, p2: ContractAddress, p1_team: u16, p2_team: u16) -> u64 {
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
                active_move_step_effects: ArrayTrait::new(),
                active_end_of_turn_effects: ArrayTrait::new(),
                effect_counter: 0,
            };

            let p1_types = array![0 + p1_team, 4 + p1_team, 8 + p1_team, 12 + p1_team, 16 + p1_team, 20 + p1_team];
            let p2_types = array![0 + p2_team, 4 + p2_team, 8 + p2_team, 12 + p2_team, 16 + p2_team, 20 + p2_team];

            let p1_cap1 = Cap {
                id: global.cap_counter + 1,
                owner: p1,
                position: Vec2 { x: 2, y: 0 },
                cap_type: *p1_types[0],
                dmg_taken: 0,
            };
            let p1_cap2 = Cap {
                id: global.cap_counter + 2,
                owner: p1,
                position: Vec2 { x: 4, y: 0 },
                cap_type: *p1_types[1],
                dmg_taken: 0,
            };

            let p1_cap3 = Cap {
                id: global.cap_counter + 3,
                owner: p1,
                position: Vec2 { x: 3, y: 0 },
                cap_type: *p1_types[2],
                dmg_taken: 0,
            };

            let p1_cap4 = Cap {
                id: global.cap_counter + 4,
                owner: p1,
                position: Vec2 { x: 1, y: 0 },
                cap_type: *p1_types[3],
                dmg_taken: 0,
            };
            let p1_cap5 = Cap {
                id: global.cap_counter + 5,
                owner: p1,
                position: Vec2 { x: 5, y: 0 },
                cap_type: *p1_types[4],
                dmg_taken: 0,
            };

            let p1_cap6 = Cap {
                id: global.cap_counter + 6,
                owner: p1,
                position: Vec2 { x: 3, y: 1 },
                cap_type: *p1_types[5],
                dmg_taken: 0,
            };


            let p2_cap1 = Cap {
                id: global.cap_counter + 7,
                owner: p2,
                position: Vec2 { x: 2, y: 6 },
                cap_type: *p2_types[0],
                dmg_taken: 0,
            };

            let p2_cap2 = Cap {
                id: global.cap_counter + 8,
                owner: p2,
                position: Vec2 { x: 4, y: 6 },
                cap_type: *p2_types[1],
                dmg_taken: 0,
            };

            

            let p2_cap3 = Cap {
                id: global.cap_counter + 9,
                owner: p2,
                position: Vec2 { x: 3, y: 6 },
                cap_type: *p2_types[2],
                dmg_taken: 0,
            };

            let p2_cap4 = Cap {
                id: global.cap_counter + 10,
                owner: p2,
                position: Vec2 { x: 1, y: 6 },
                cap_type: *p2_types[3],
                dmg_taken: 0,
            };

            let p2_cap5 = Cap {
                id: global.cap_counter + 11,
                owner: p2,
                position: Vec2 { x: 5, y: 6 },
                cap_type: *p2_types[4],
                dmg_taken: 0,
            };

            let p2_cap6 = Cap {
                id: global.cap_counter + 12,
                owner: p2,
                position: Vec2 { x: 3, y: 5 },
                cap_type: *p2_types[5],
                dmg_taken: 0,
            };

            game.add_cap(p1_cap1.id);
            game.add_cap(p1_cap2.id);
            game.add_cap(p1_cap3.id);
            game.add_cap(p1_cap4.id);
            game.add_cap(p1_cap5.id);
            game.add_cap(p1_cap6.id);
            game.add_cap(p2_cap1.id);
            game.add_cap(p2_cap2.id);
            game.add_cap(p2_cap3.id);
            game.add_cap(p2_cap4.id);
            game.add_cap(p2_cap5.id);
            game.add_cap(p2_cap6.id);

            global.cap_counter = global.cap_counter + 12;

            world.write_model(@game);
            world.write_model(@p1_cap1);
            world.write_model(@p1_cap2);
            world.write_model(@p1_cap3);
            world.write_model(@p1_cap4);
            world.write_model(@p1_cap5);
            world.write_model(@p1_cap6);
            world.write_model(@p2_cap1);
            world.write_model(@p2_cap2);
            world.write_model(@p2_cap3);
            world.write_model(@p2_cap4);
            world.write_model(@p2_cap5);
            world.write_model(@p2_cap6);

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

            let (start_of_turn_effects, move_step_effects, end_of_turn_effects) = get_active_effects(game_id, @world);

            let mut stunned: bool = false;
            let mut stun_effect_ids: Array<u64> = ArrayTrait::new();

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
                let (start_of_turn_effects, move_step_effects, end_of_turn_effects) = get_active_effects(game_id, @world);
                game = world.read_model(game_id);

                let action = turn.at(i);
                let mut locations = get_piece_locations(game_id, @world);
                let mut cap: Cap = world.read_model(*action.cap_id);
                assert!(cap.owner == get_caller_address(), "You are not the owner of this piece");
                let cap_type = self.get_cap_data(cap.cap_type).unwrap();

                //Triggers on Attack
                let mut attack_bonus_amount: u8 = 0;
                let mut attack_bonus_ids: Array<u64> = ArrayTrait::new();

                //Triggers on Move
                let mut move_discount_amount: u8 = 0;
                let mut move_discount_ids: Array<u64> = ArrayTrait::new();

                //Triggers on Attack
                let mut attack_discount_amount: u8 = 0;
                let mut attack_discount_ids: Array<u64> = ArrayTrait::new();

                //Triggers on Ability
                let mut ability_discount_amount: u8 = 0;
                let mut ability_discount_ids: Array<u64> = ArrayTrait::new();
                
                //Triggers on Move
                let mut bonus_range_amount: u8 = 0;
                let mut bonus_range_ids: Array<u64> = ArrayTrait::new();

                let mut double: bool = false;
                let mut double_ids: Array<u64> = ArrayTrait::new();

                let mut untriggered_move_step_effects: Array<u64> = ArrayTrait::new();
                let mut untriggered_attack_step_effects: Array<u64> = ArrayTrait::new();

                let mut index = 0;
                while index < move_step_effects.len() {
                    let effect: Effect = *move_step_effects.at(index);

                    match effect.effect_type {
                        EffectType::Double => {
                            double = true;
                            double_ids.append(effect.effect_id);
                        },
                        EffectType::MoveDiscount(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == cap.id {
                                        move_discount_ids.append(effect.effect_id);
                                        move_discount_amount += x;
                                    }
                                    else {
                                        untriggered_move_step_effects.append(effect.effect_id);
                                    }
                                },
                                _ => {
                                    continue;
                                }
                            }
                        },
                        EffectType::AttackDiscount(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == cap.id {
                                        attack_discount_ids.append(effect.effect_id);
                                        attack_discount_amount += x;
                                    }
                                    else {
                                        untriggered_move_step_effects.append(effect.effect_id);
                                    }
                                },
                                _ => {
                                    continue;
                                }
                            }
                        },
                        EffectType::AbilityDiscount(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == cap.id {
                                        ability_discount_ids.append(effect.effect_id);
                                        ability_discount_amount += x;
                                    }
                                    else {
                                        untriggered_move_step_effects.append(effect.effect_id);
                                    }
                                },
                                _ => {
                                    continue;
                                }
                            }
                        },   
                        EffectType::AttackBonus(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == cap.id {
                                        attack_bonus_ids.append(effect.effect_id);
                                        attack_bonus_amount += x;
                                    }
                                    else {
                                        untriggered_move_step_effects.append(effect.effect_id);
                                    }
                                },
                                _ => {
                                    continue;
                                }
                            }
                        },
                        EffectType::BonusRange(x) => {
                            match effect.target {
                                EffectTarget::Cap(id) => {
                                    if id == cap.id {
                                        bonus_range_ids.append(effect.effect_id);
                                        bonus_range_amount += x;
                                    }
                                    else {
                                        untriggered_move_step_effects.append(effect.effect_id);
                                    }
                                },
                                _ => {
                                    continue;
                                }
                            }
                        },
                        _ => {
                            continue;
                        }
                    }


                    index += 1;
                };

                let mut j = 0;
                while j < end_of_turn_effects.len() {
                    let effect: Effect = *end_of_turn_effects.at(i);
                    match effect.effect_type {
                        EffectType::Stun => {
                            stunned = true;
                            stun_effect_ids.append(effect.effect_id);
                        },
                        _ => {
                            continue;
                        }
                    }
                    j += 1;
                };
                match action.action_type {
                    ActionType::Move(dir) => {
                        assert!(energy >= cap_type.move_cost, "Not enough energy");
                        let mut move_cost = cap_type.move_cost;
                        if move_discount_amount > move_cost {
                            move_cost = 0;
                        }
                        else {
                            move_cost -= move_discount_amount;
                        }
                        if stunned {
                            let mut j = 0;
                            while j < stun_effect_ids.len() {
                                let mut effect: Effect = world.read_model((game_id, *stun_effect_ids.at(j)).into());
                                match effect.target {
                                    EffectTarget::Cap(id) => {
                                        if id == cap.id {
                                            panic!("Cannot move stunned cap");
                                            
                                        }
                                    },
                                    _ => {
                                        
                                    }
                                }
                                j += 1;
                            }
                        }
                        energy -= move_cost;
                        let new_location_index = cap.get_new_index_from_dir(*dir.x, *dir.y);
                        let piece_at_location_id = locations.get(new_location_index.into());
                        assert!(piece_at_location_id == 0, "There is a piece at the new location");
                        cap.move(cap_type, *dir.x, *dir.y, bonus_range_amount);
                        world.write_model(@cap);

                        for attack_discount_id in attack_discount_ids {
                            untriggered_move_step_effects.append(attack_discount_id);
                        };
                        for move_discount_id in move_discount_ids {
                            untriggered_move_step_effects.append(move_discount_id);
                        };
                        for ability_discount_id in ability_discount_ids {
                            untriggered_move_step_effects.append(ability_discount_id);
                        }
                    },
                    ActionType::Attack(target) => {
                        assert!(energy >= cap_type.attack_cost, "Not enough energy");
                        let mut attack_cost = cap_type.attack_cost;
                        if attack_discount_amount > attack_cost {
                            attack_cost = 0;
                        }
                        else {
                            attack_cost -= attack_discount_amount;
                        }
                        let mut k = 0;
                        while k < attack_discount_ids.len() {
                            let mut attack_discount_effect: Effect = world.read_model((game_id, *attack_discount_ids.at(k)));
                            attack_discount_effect.remaining_triggers -= 1;
                            if attack_discount_effect.remaining_triggers == 0 {
                                world.erase_model(@attack_discount_effect);
                            }
                            else {
                                untriggered_move_step_effects.append(attack_discount_effect.effect_id);
                                world.write_model(@attack_discount_effect);
                            }
                            k += 1;
                        };
                        energy -= attack_cost;
                        let mut attack_dmg = cap_type.attack_dmg;
                        if attack_bonus_amount > 0 {
                            attack_dmg += attack_bonus_amount.into();
                        }
                        let mut l = 0;
                        while l < attack_bonus_ids.len() {
                            let mut attack_bonus_effect: Effect = world.read_model((game_id, *attack_bonus_ids.at(l)));
                            attack_bonus_effect.remaining_triggers -= 1;
                            if attack_bonus_effect.remaining_triggers == 0 {
                                world.erase_model(@attack_bonus_effect);
                            }
                            else {
                                untriggered_move_step_effects.append(attack_bonus_effect.effect_id);
                                world.write_model(@attack_bonus_effect);
                            }
                            l += 1;
                        };
                        
                        let piece_at_location_id = locations.get((*target.x * 7 + *target.y).into());
                        let mut piece_at_location: Cap = world.read_model(piece_at_location_id);
                        assert!(piece_at_location_id != 0, "There is no piece at the target location");
                        assert!(piece_at_location.owner != get_caller_address(), "You cannot attack your own piece");
                        if(!cap.check_in_range(*target, @cap_type.attack_range)) {
                            panic!("Attack is not valid");
                        }
                        handle_damage(game_id, piece_at_location.id, ref world, attack_dmg.try_into().unwrap());

                        
                        for ability_discount_id in ability_discount_ids {
                            untriggered_move_step_effects.append(ability_discount_id);
                        };
                        for bonus_range_id in bonus_range_ids {
                            untriggered_move_step_effects.append(bonus_range_id);
                        };
                        for move_discount_id in move_discount_ids {
                            untriggered_move_step_effects.append(move_discount_id);
                        };
                        
                    },
                    ActionType::Ability(target) => {
                        let mut cap_type = self.get_cap_data(cap.cap_type).unwrap();
                        let mut cap_type_2 = self.get_cap_data(cap.cap_type).unwrap();
                        let mut cap_type_3 = self.get_cap_data(cap.cap_type).unwrap();
                        assert!(cap_type.ability_target != TargetType::None, "Ability should not be none");
                        assert!(cap_type.ability_target.is_valid(@cap, ref cap_type_2, *target, game_id, @world), "Ability is not valid");
                        let mut ability_cost = cap_type.ability_cost;
                        if ability_discount_amount > ability_cost {
                            ability_cost = 0;
                        }
                        else {
                            ability_cost -= ability_discount_amount;
                        }
                        if ability_cost > energy {
                            panic!("Not enough energy");
                        }
                        energy -= ability_cost;
                        let mut m = 0;
                        while m < ability_discount_ids.len() {
                            let mut ability_discount_effect: Effect = world.read_model((game_id, *ability_discount_ids.at(m)));
                            ability_discount_effect.remaining_triggers -= 1;
                            if ability_discount_effect.remaining_triggers == 0 {
                                world.erase_model(@ability_discount_effect);
                            }
                            else {
                                untriggered_move_step_effects.append(ability_discount_effect.effect_id);
                                world.write_model(@ability_discount_effect);
                            }
                            m += 1;
                        };
                        for bonus_range_id in bonus_range_ids {
                            untriggered_move_step_effects.append(bonus_range_id);
                        };
                        for move_discount_id in move_discount_ids {
                            untriggered_move_step_effects.append(move_discount_id);
                        };
                        for attack_discount_id in attack_discount_ids {
                            untriggered_move_step_effects.append(attack_discount_id);
                        };
                        for attack_bonus_id in attack_bonus_ids {
                            untriggered_move_step_effects.append(attack_bonus_id);
                        };
                        cap.use_ability(cap_type, *target, game_id, ref world);

                        if double && cap_type_3.ability_target.is_valid(@cap, ref cap_type_3, *target, game_id, @world) {
                            cap.use_ability(cap_type_3, *target, game_id, ref world);
                        }

                        for double_id in double_ids {
                            let mut double_effect: Effect = world.read_model((game_id, double_id));
                            double_effect.remaining_triggers -= 1;
                            if double_effect.remaining_triggers == 0 {
                                world.erase_model(@double_effect);
                            }
                            else {
                                untriggered_move_step_effects.append(double_effect.effect_id);
                                world.write_model(@double_effect);
                            }
                        };
                    }
                };
                update_move_step_effects(game_id, ref world, untriggered_move_step_effects);
                i = i + 1;
            };

            game.turn_count = game.turn_count + 1;
            let (over, _) = @game.check_over(@world);
            game.over = *over;
            world.write_model(@game);

            world.emit_event(@Moved { player: get_caller_address(), game_id: game_id, turn_number: game.turn_count-1, turn: clone.span() });
        }

        fn get_game(self: @ContractState, game_id: u64) -> Option<(Game, Span<Cap>, Span<Effect>)> {
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

            let mut i: u64 = 0;
            let mut effects: Array<Effect> = ArrayTrait::new();
            while i < game.effect_counter {
                let effect: Effect = world.read_model((game_id, i).into());
                if effect.remaining_triggers > 0 {
                    effects.append(effect);
                }
                i += 1;
            };
            Option::Some((game, caps.span(), effects.span()))
        }

        fn get_cap_data(self: @ContractState, cap_type: u16) -> Option<CapType> {
            
            get_cap_type(cap_type)
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
