use caps::models::game::{Game, Action};
use caps::models::cap::{Cap, CapType};
use caps::models::effect::{Effect};
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
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use caps::models::game::{Vec2, Game, Global, GameTrait, Action, ActionType,};
    use caps::models::effect::{Effect, EffectTrait, EffectType, EffectTarget, Timing};
    use caps::models::cap::{Cap, CapTrait, CapType, TargetType, TargetTypeTrait};
    use caps::sets::set_zero::get_cap_type;
    use caps::helpers::handle_damage;
    use caps::helpers::{get_player_pieces, get_move_step_effects, check_includes, get_piece_locations, get_active_effects, update_end_of_turn_effects, handle_start_of_turn_effects};
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
                effect_ids: ArrayTrait::new(),
                last_action_timestamp: get_block_timestamp(),
            };

            let mut p1_types: Array<u16> = ArrayTrait::new();
            let mut p2_types: Array<u16> = ArrayTrait::new();

            let p1_types = array![0 + p1_team, 4 + p1_team, 8 + p1_team, 12 + p1_team, 16 + p1_team, 20 + p1_team];
            let p2_types = array![0 + p2_team, 4 + p2_team, 8 + p2_team, 12 + p2_team, 16 + p2_team, 20 + p2_team];

            let p1_cap1 = Cap {
                id: global.cap_counter + 1,
                owner: p1,
                position: Vec2 { x: 2, y: 0 },
                cap_type: *p1_types[0],
                dmg_taken: 0,
                shield_amt: 0,
            };
            let p1_cap2 = Cap {
                id: global.cap_counter + 2,
                owner: p1,
                position: Vec2 { x: 4, y: 0 },
                cap_type: *p1_types[1],
                dmg_taken: 0,
                shield_amt: 0,
            };

            let p1_cap3 = Cap {
                id: global.cap_counter + 3,
                owner: p1,
                position: Vec2 { x: 3, y: 0 },
                cap_type: *p1_types[2],
                dmg_taken: 0,
                shield_amt: 0,
            };

            let p1_cap4 = Cap {
                id: global.cap_counter + 4,
                owner: p1,
                position: Vec2 { x: 1, y: 0 },
                cap_type: *p1_types[3],
                dmg_taken: 0,
                shield_amt: 0,
            };
            let p1_cap5 = Cap {
                id: global.cap_counter + 5,
                owner: p1,
                position: Vec2 { x: 5, y: 0 },
                cap_type: *p1_types[4],
                dmg_taken: 0,
                shield_amt: 0,
            };

            let p1_cap6 = Cap {
                id: global.cap_counter + 6,
                owner: p1,
                position: Vec2 { x: 3, y: 1 },
                cap_type: *p1_types[5],
                dmg_taken: 0,
                shield_amt: 0,
            };


            let p2_cap1 = Cap {
                id: global.cap_counter + 7,
                owner: p2,
                position: Vec2 { x: 2, y: 6 },
                cap_type: *p2_types[0],
                dmg_taken: 0,
                shield_amt: 0,
            };

            let p2_cap2 = Cap {
                id: global.cap_counter + 8,
                owner: p2,
                position: Vec2 { x: 4, y: 6 },
                cap_type: *p2_types[1],
                dmg_taken: 0,
                shield_amt: 0,
            };

            

            let p2_cap3 = Cap {
                id: global.cap_counter + 9,
                owner: p2,
                position: Vec2 { x: 3, y: 6 },
                cap_type: *p2_types[2],
                dmg_taken: 0,
                shield_amt: 0,
            };

            let p2_cap4 = Cap {
                id: global.cap_counter + 10,
                owner: p2,
                position: Vec2 { x: 1, y: 6 },
                cap_type: *p2_types[3],
                dmg_taken: 0,
                shield_amt: 0,
            };

            let p2_cap5 = Cap {
                id: global.cap_counter + 11,
                owner: p2,
                position: Vec2 { x: 5, y: 6 },
                cap_type: *p2_types[4],
                dmg_taken: 0,
                shield_amt: 0,
            };

            let p2_cap6 = Cap {
                id: global.cap_counter + 12,
                owner: p2,
                position: Vec2 { x: 3, y: 5 },
                cap_type: *p2_types[5],
                dmg_taken: 0,
                shield_amt: 0,
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
            world.write_model(@global);

            game_id
        }

        fn take_turn(ref self: ContractState, game_id: u64, turn: Array<Action>) {
            let mut world = self.world_default();

            let clone = turn.clone();
            let mut game: Game = world.read_model(game_id);

            let (over, _) = @game.check_over(@world);
            if *over {
                if !game.over {
                    game.over = true;
                    world.write_model(@game);
                    return;
                }
                panic!("Game is over");
            }



            if game.turn_count % 2 == 0 {
                assert!(get_caller_address() == game.player1, "You are not the turn player, 1s turn");
            }
            else {
                assert!(get_caller_address() == game.player2, "You are not the turn player, 2s turn");
            }

            let (mut start_of_turn_effects, _, mut end_of_turn_effects) = get_active_effects(ref game, @world);

            //handle start of turn effects
            let (mut game, extra_energy, stunned_pieces) = handle_start_of_turn_effects(ref game, ref start_of_turn_effects, ref world);

            let mut energy: u8 = game.turn_count.try_into().unwrap() + 2 + extra_energy;

            let (mut move_effects, mut attack_effects, mut ability_effects) = get_move_step_effects(ref game, ref world);

            let mut i = 0;
            while i < turn.len() {

                let action = turn.at(i);
                let mut locations = get_piece_locations(ref game, @world);
                let mut cap: Cap = world.read_model(*action.cap_id);
                assert!(cap.owner == get_caller_address(), "You are not the owner of this piece");
                assert!(!check_includes(@stunned_pieces, cap.id), "Piece is stunned");
                let cap_type: CapType = self.get_cap_data(cap.cap_type).unwrap();
                let mut new_effects: Array<Effect> = ArrayTrait::new();


                match action.action_type {
                    ActionType::Move(dir) => {
                        assert!(energy >= cap_type.move_cost, "Not enough energy");
                        let mut move_discount: u8 = 0;
                        let mut move_bonus: u8 = 0;
                        let mut new_move_effects: Array<Effect> = ArrayTrait::new();
                        for mut effect in move_effects {
                            match effect.effect_type {
                                EffectType::MoveDiscount(x) => {
                                    move_discount += x;
                                    effect.trigger();
                                    if effect.remaining_triggers > 0 {
                                        new_move_effects.append(effect);
                                    }
                                },
                                EffectType::MoveBonus(x) => {
                                    move_bonus += x;
                                    effect.trigger();
                                    if effect.remaining_triggers > 0 {
                                        new_move_effects.append(effect);
                                    }
                                },
                                _ => {}
                            }
                        };
                        move_effects = new_move_effects;
                        let mut move_cost = cap_type.move_cost;
                        if move_discount > cap_type.move_cost {
                            move_cost = 0;
                        }
                        else {
                            move_cost -= move_discount;
                        }
                        assert!(move_cost <= energy, "Not enough energy");
                        energy -= move_cost;
                        let new_location_index = cap.get_new_index_from_dir(*dir.x, *dir.y);
                        let piece_at_location_id = locations.get(new_location_index.into());
                        assert!(piece_at_location_id == 0, "There is a piece at the new location");
                        cap.move(cap_type, *dir.x, *dir.y, move_bonus);
                        world.write_model(@cap);

                    },
                    ActionType::Attack(target) => {
                        assert!(energy >= cap_type.attack_cost, "Not enough energy");
                        let mut attack_cost = cap_type.attack_cost;
                        let mut attack_discount: u8 = 0;
                        let mut attack_bonus: u8 = 0;
                        
                        let mut new_attack_effects: Array<Effect> = ArrayTrait::new();

                        for mut effect in attack_effects {
                            match effect.effect_type {
                                EffectType::AttackDiscount(x) => {
                                    attack_discount += x;
                                    effect.trigger();
                                    if effect.remaining_triggers > 0 {
                                        new_attack_effects.append(effect);
                                    }
                                },
                                EffectType::AttackBonus(x) => {
                                    attack_bonus += x;
                                    effect.trigger();
                                    if effect.remaining_triggers > 0 {
                                        new_attack_effects.append(effect);
                                    }
                                },
                                _ => {}
                            }
                        };
                        attack_effects = new_attack_effects;
                        if attack_discount > cap_type.attack_cost {
                            attack_cost = 0;
                        }
                        else {
                            attack_cost -= attack_discount;
                        }
                        
                        assert!(attack_cost <= energy, "Not enough energy");
                        energy -= attack_cost;
                        let mut attack_dmg = cap_type.attack_dmg;
                        attack_dmg += attack_bonus.into();
                        
                        let piece_at_location_id = locations.get((*target.x * 7 + *target.y).into());
                        let mut piece_at_location: Cap = world.read_model(piece_at_location_id);
                        assert!(piece_at_location_id != 0, "There is no piece at the target location");
                        assert!(piece_at_location.owner != get_caller_address(), "You cannot attack your own piece");
                        if(!cap.check_in_range(*target, @cap_type.attack_range)) {
                            panic!("Attack is not valid");
                        }
                        game = handle_damage(ref game, piece_at_location.id, ref world, attack_dmg.try_into().unwrap());

                        
                    },
                    ActionType::Ability(target) => {
                        let mut cap_type: CapType = self.get_cap_data(cap.cap_type).unwrap();
                        assert!(cap_type.ability_target != TargetType::None, "Ability should not be none");
                        let (valid, new_game) = cap_type.ability_target.is_valid(@cap, ref cap_type, *target, ref game, @world);
                        game = new_game;
                        assert!(valid, "Ability is not valid");
                        let mut ability_cost = cap_type.ability_cost;
                        let mut ability_discount = 0;
                        let mut double_count: u8 = 0;
                        
                        let mut new_ability_effects: Array<Effect> = ArrayTrait::new();
                        for mut effect in ability_effects {
                            match effect.effect_type {
                                EffectType::AbilityDiscount(x) => {
                                    ability_discount += x;
                                    effect.trigger();
                                    if effect.remaining_triggers > 0 {
                                        new_ability_effects.append(effect);
                                    }
                                },
                                EffectType::Double(x) => {
                                    double_count += x;
                                    effect.trigger();
                                    if effect.remaining_triggers > 0 {
                                        new_ability_effects.append(effect);
                                    }
                                },
                                _ => {}
                            }
                        };
                        ability_effects = new_ability_effects;
                        if ability_discount > cap_type.ability_cost {
                            ability_cost = 0;
                        }
                        else {
                            ability_cost -= ability_discount;
                        }

                        assert!(ability_cost <= energy, "Not enough energy");
                        energy -= ability_cost;
                        

                        let (mut game, mut created_effects) = cap.use_ability(ref cap_type, *target, ref game, ref world);
                        for effect in created_effects {
                            new_effects.append(effect);
                        };

                        while double_count > 0 {
                            let (valid, new_game) = cap_type.ability_target.is_valid(@cap, ref cap_type, *target, ref game, @world);
                            game = new_game;
                            if valid {
                                let (mut game, new_double_effects) = cap.use_ability(ref cap_type, *target, ref game, ref world);
                                for effect in new_double_effects {
                                    new_effects.append(effect);
                                };
                                double_count -= 1;
                                game = new_game;
                            }
                            else {
                                double_count = 0;
                            }
                        }
                        
                    }
                };

                for effect in new_effects {
                    match effect.get_timing() {
                        Timing::StartOfTurn => {
                            start_of_turn_effects.append(effect);
                        },
                        Timing::MoveStep => {
                            move_effects.append(effect);
                        },
                        Timing::EndOfTurn => {
                            end_of_turn_effects.append(effect);
                        },
                        _ => {}
                    }
                };
                
            };

            game = update_end_of_turn_effects(ref game, ref end_of_turn_effects, ref world);

            game.last_action_timestamp = get_block_timestamp();
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
            while i < game.effect_ids.len().into() {
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
