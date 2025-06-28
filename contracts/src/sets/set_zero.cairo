use caps::models::cap::{Cap,CapType, TargetType};
use caps::models::effect::{Effect, EffectType, EffectTarget};
use caps::helpers::{get_piece_locations, handle_damage};
use caps::models::game::{Vec2, Game, GameTrait};
use dojo::world::WorldStorage;
use dojo::model::{ModelStorage};
use core::dict::{Felt252Dict, Felt252DictTrait, SquashedFelt252Dict};

#[dojo::contract]
pub mod set_zero {
    use caps::models::set::{ISetInterface, Set};
    use super::{get_cap_type, use_ability};
    use caps::models::cap::{Cap, CapType};
    use caps::models::game::{Game, Vec2};
    use caps::models::effect::Effect;
    use core::dict::Felt252Dict;
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage};

    fn dojo_init(ref self: ContractState) {
        let mut world: WorldStorage = self.world(@"caps");
        let set = Set {
            id: 0,
            address: world.dns_address(@"set_zero").unwrap(),
        };
        world.write_model(@set);
    }

    #[abi(embed_v0)]
    impl SetZeroImpl of ISetInterface<ContractState> {
        fn get_cap_type(self: @ContractState, id: u16) -> Option<CapType> {
            get_cap_type(id)
        }

        fn activate_ability(ref self: ContractState, cap: Cap, target: Vec2, game: Game, locations: Felt252Dict<Nullable<Cap>>) -> (Game, Array<Effect>, Felt252Dict<Nullable<Cap>>) {
            // Ideally we should change this so it doesn't need to write to the world. 
            // Which mostly means returning the updated caps instead of writing them
            let mut cap = cap;
            let mut game = game;
            let mut cap_type = get_cap_type(cap.cap_type).unwrap();
            let mut locations = locations;
            use_ability(ref cap, ref cap_type, target, ref game, ref locations)
        }
    }
}


pub fn get_cap_type(cap_type: u16) -> Option<CapType> {
    let res = match cap_type {
        0 => Option::Some(CapType {
            id: 0,
            name: "Red Tower",
            description: "Red Tower",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
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
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
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
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
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
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
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
            attack_cost: 1,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 1 } , Vec2 { x: 1, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 1 }],
            ability_description: "Deal 4 damage to an enemy",
            move_range: Vec2 { x: 1, y: 2 },
            attack_dmg: 2,
            base_health: 8,
            ability_target: TargetType::OpponentCap,
            ability_cost: 2,
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
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 7,
            ability_target: TargetType::TeamCap,
            ability_cost: 3,
        }),
        6 => Option::Some(CapType {
            id: 6,
            name: "Yellow Basic",
            description: "Cap 5",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 1, y: 1 }, Vec2 { x: 2, y: 2 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Shield an ally for 5",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 9,
            ability_target: TargetType::TeamCap,
            ability_cost: 3,
        }),
        7 => Option::Some(CapType {
            id: 7,
            name: "Green Basic",
            description: "Cap 6",
            move_cost: 1,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 1, y: 1 }, Vec2 { x: 2, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_description: "Target unit's next ability use costs 1 less energy",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 6,
            ability_target: TargetType::TeamCap,
            ability_cost: 2,

        }),
        8 => Option::Some(CapType {
            id: 8,
            name: "Red Elite",
            description: "Cap 8",
            move_cost: 2,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_range: array![],
            ability_description: "Next attack deals 1 more damage for each damage this unit has taken",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 5,
            base_health: 14,
            ability_target: TargetType::SelfCap,
            ability_cost: 4,
        }),
        9 => Option::Some(CapType {
            id: 9,
            name: "Blue Elite",
            description: "Cap 9",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Fully heal this unit, then damage an enemy unit equal to the amount healed",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 11,
            ability_target: TargetType::OpponentCap,
            ability_cost: 2,
        }),
        10 => Option::Some(CapType {
            id: 10,
            name: "Yellow Elite",
            description: "Cap 10",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 {x: 1, y: 2}, Vec2 {x: 2, y: 1}],
            ability_range: array![],
            ability_description: "Gain free attacks equal to the strength of this cards shield",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 2,
            base_health: 13,
            ability_target: TargetType::SelfCap,
            ability_cost: 5,
        }),
        11 => Option::Some(CapType {
            id: 11,
            name: "Green Elite",
            description: "Cap 11",
            move_cost: 3,
            attack_cost: 5,
            attack_range: array![Vec2 { x: 1, y: 0}, Vec2 {x: 2, y: 0}, Vec2 {x: 1, y: 1}],
            ability_range: array![],
            ability_description: "Next turn gain 2 energy. This card becomes stunned next turn and recieves a 2 health shield",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 8,
            base_health: 16,
            ability_target: TargetType::SelfCap,
            ability_cost: 3,
        }),
        12 => Option::Some(CapType {
            id: 12,
            name: "Red Mage",
            description: "Red Mage",
            move_cost: 2,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 {x:3, y:3}, Vec2 {x: 2, y: 2}],
            ability_description: "Deal 1 damage to an ally to make its next attack deal 3 more damage",
            move_range: Vec2 { x: 3, y: 2 },
            attack_dmg: 1,
            base_health: 12,
            ability_target: TargetType::TeamCap,
            ability_cost: 1,
        }),
        13 => Option::Some(CapType {
            id: 13,
            name: "Blue Mage",
            description: "Blue Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 {x: 2, y: 0}],
            ability_description: "Stun a target enemy unit",
            move_range: Vec2 { x: 2, y: 1 },
            attack_dmg: 1,
            base_health: 13,
            ability_target: TargetType::OpponentCap,
            ability_cost: 3,
        }),
        14 => Option::Some(CapType {
            id: 14,
            name: "Yellow Mage",
            description: "Yellow Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 {x: 2, y: 0},  Vec2 {x: 0, y: 2}],
            ability_description: "Target unit gains move range equal to its shield health",
            move_range: Vec2 { x: 3, y: 2 },
            attack_dmg: 1,
            base_health: 10,
                ability_target: TargetType::TeamCap,
            ability_cost: 2,
        }),
        15 => Option::Some(CapType {
            id: 15,
            name: "Green Mage",
            description: "Green Mage",
            move_cost: 1,
            attack_cost: 1,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }],
            ability_description: "Repeat the effect of the ally's next ability (if possible)",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 1,
            base_health: 10,
            ability_target: TargetType::SelfCap,
            ability_cost: 0,
        }),
        16 => Option::Some(CapType {
            id: 16,
            name: "Red Dragon",
            description: "Cap 3",
            move_cost: 5,
            attack_cost: 6,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 {x: 1, y: 1}, Vec2 {x: 2, y: 2}, Vec2 {x: 2, y: 0}],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_description: "Inflict target with burn that deals 3 damage each turn for 3 turns",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 9,
            base_health: 20,
            ability_target: TargetType::OpponentCap,
            ability_cost: 5,
        }),
        17 => Option::Some(CapType {
            id: 17,
            name: "Blue Mermaid",
            description: "Blue Mermaid",
            move_cost: 3,
            attack_cost: 3,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Target unit heals 2 health per turn at the end of the next 3 turns",
            move_range: Vec2 { x: 2, y: 1 },
            attack_dmg: 6,
            base_health: 15,
            ability_target: TargetType::TeamCap,
            ability_cost: 3,
        }),
        18 => Option::Some(CapType {
            id: 18,
            name: "Yellow Trickster",
            description: "Yellow Trickster",
            move_cost: 2,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![],
            ability_description: "Double the strength of this unit's shield",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 12,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        19 => Option::Some(CapType {
            id: 19,
            name: "Green Tank",
            description: "Green Tank",
            move_cost: 6,
            attack_cost: 7,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Next attack deals 1 more damage for each extra energy you started this turn with",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 13,
            base_health: 25,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        20 => Option::Some(CapType {
            id: 20,
            name: "Red Knight",
            description: "Red Knight",
            move_cost: 2,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 {x: 1, y: 1}],
            ability_description: "Deal 4 damage to self and 7 damage to an enemy",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 6,
            base_health: 16,
            ability_target: TargetType::OpponentCap,
            ability_cost: 4,
        }),
        21 => Option::Some(CapType {
            id: 21,
            name: "Blue Elite",
            description: "Cap 9",
            move_cost: 1,
            attack_cost: 2,
            attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Deal 8 damage to an enemy, but stun this unit next turn",
            move_range: Vec2 { x: 2, y: 2 },
            attack_dmg: 3,
            base_health: 11,
            ability_target: TargetType::OpponentCap,
            ability_cost: 2,
        }),
        22 => Option::Some(CapType {
            id: 22,
            name: "Yellow Elite",
            description: "Cap 10",
            move_cost: 3,
            attack_cost: 5,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Gain shield equal to target unit's shield",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 8,
            base_health: 26,
            ability_target: TargetType::TeamCap,
            ability_cost: 4,
        }),
        23 => Option::Some(CapType {
            id: 23,
            name: "Green Elite",
            description: "Cap 11",
            move_cost: 3,
            attack_cost: 5,
            attack_range: array![Vec2 { x: 0, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 1, y: 0 }, Vec2 { x: 2, y: 0 }],
            ability_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }, Vec2 { x: 0, y: 2 }, Vec2 { x: 2, y: 0 }, Vec2 { x: 1, y: 2 }, Vec2 { x: 2, y: 1 }],
            ability_description: "Heal all allies for 2 health, plus 1 health per extra energy you started this turn with",
            move_range: Vec2 { x: 3, y: 3 },
            attack_dmg: 10,
            base_health: 26,
            ability_target: TargetType::SelfCap,
            ability_cost: 2,
        }),
        _ => Option::None,
    };
    res
}

fn use_ability(ref cap: Cap, ref cap_type: CapType, target: Vec2, ref game: Game, ref locations: Felt252Dict<Nullable<Cap>>) -> (Game, Array<Effect>, Felt252Dict<Nullable<Cap>>) {
    let mut new_effects: Array<Effect> = ArrayTrait::new();
    let mut new_locations: Felt252Dict<Nullable<Cap>> = Default::default();
    match cap_type.id {
        0 => {
            // "None"
        },
        1 => {
            // "None"
        },
        2 => {
            // "None"
        },
        3 => {
            // "None"
            },
        4 => {
            // "Deal 4 damage to an enemy"
            let mut cap = locations.get((target.x * 7 + target.y).into()).deref();
            let (new_game, new_cap) = handle_damage(ref game, ref cap, 4);
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(new_cap));
            game = new_game;
        },
        5 => {
            // "Heal 5 damage from an ally"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            if cap_at_target.dmg_taken < 5 {
                cap_at_target.dmg_taken = 0;
            }
            else {
                cap_at_target.dmg_taken -= 5;
            }
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(cap_at_target));
        },
        6 => {
            // "Shield an ally for 5"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            cap_at_target.shield_amt += 5;
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(cap_at_target));
        },
        7 => {
            // "Target unit's next ability use costs 1 less energy"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::AbilityDiscount(1),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 1,
            };
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        8 => {
            // "Next attack deals 1 more damage for each damage this unit has taken"
            let effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::AttackBonus(cap.dmg_taken.try_into().unwrap()),
                target: EffectTarget::Cap(cap.id),
                remaining_triggers: 1,
            };
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        9 => {
            // "Fully heal this unit, then damage an enemy unit equal to the amount healed"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let (new_game, new_cap) = handle_damage(ref game, ref cap_at_target, cap.dmg_taken.into());
            cap_at_target = new_cap;
            game = new_game;
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(cap_at_target));
        },
        10 => {
            // "Gain free attacks equal to the strength of this cards shield"
            let cap_type = get_cap_type(cap.cap_type);
            let new_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::AttackDiscount(cap_type.unwrap().attack_cost.try_into().unwrap()),
                target: EffectTarget::Cap(cap.id),
                remaining_triggers: cap.shield_amt.try_into().unwrap(),
            };
            new_effects.append(new_effect);
            game.effect_ids.append(new_effect.effect_id);
                                    
        },
        11 => {
            // "Next turn gain 2 energy. This card becomes stunned next turn and recieves a 2 health shield"
            let mut energy_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::ExtraEnergy(2),
                target: EffectTarget::Cap(cap.id),
                remaining_triggers: 2,
            };
            new_effects.append(energy_effect);
            game.effect_ids.append(energy_effect.effect_id);
            cap.shield_amt += 2;
            locations.insert(cap.id.into(), NullableTrait::new(cap));
        },
        12 => {
            // "Deal 1 damage to an ally to make its next attack deal 3 more damage"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let target_cap_type = get_cap_type(cap_at_target.cap_type);

            if target_cap_type.unwrap().base_health - cap_at_target.dmg_taken == 1 {
                game.remove_cap(cap_at_target.id.try_into().unwrap());
                locations.insert((target.x * 7 + target.y).into(), Default::default());
            }
            else {
                cap_at_target.dmg_taken += 1;
                let effect = Effect {
                    game_id: game.id,
                    effect_id: game.effect_ids.len().into(),
                    effect_type: EffectType::DamageBuff(3),
                    target: EffectTarget::Cap(cap_at_target.id),
                    remaining_triggers: 1,
                };
                new_effects.append(effect);
                game.effect_ids.append(effect.effect_id);
                locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(cap_at_target));
            }
        },
        13 => {
            // "Stun a target enemy unit"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let stun_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::Stun(1),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 1,
            };
            new_effects.append(stun_effect);
            game.effect_ids.append(stun_effect.effect_id);
        },
        14 => {
            // "Target unit gains move range equal to its shield health"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let new_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::MoveDiscount(cap_at_target.shield_amt.try_into().unwrap()),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 1,
            };
            new_effects.append(new_effect);
                                
        },
        15 => {
            // "Repeat the effect of the ally's next ability (if possible)"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let mut effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::Double(1),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 2,
            };
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        16 => {
            // "Inflict target with burn that deals 3 damage each turn for 3 turns"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let mut effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::DOT(1),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 3,
            };  
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        17 => {
            // "Target unit heals 2 health per turn at the end of the next 3 turns"
            let cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let mut effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::Heal(2),
                target: EffectTarget::Cap(cap_at_target.id),
                remaining_triggers: 3,
            };
            new_effects.append(effect);
            game.effect_ids.append(effect.effect_id);
        },
        18 => {
            // "Double the strength of this unit's shield"
            cap.shield_amt *= 2;
            locations.insert(cap.id.into(), NullableTrait::new(cap));
        },
        19 => {
            // "Next attack deals 1 more damage for each extra energy you started this turn with"
            //todo
        },
        20 => {
            // "Deal 4 damage to self and 7 damage to an enemy"
            let self_cap_type = get_cap_type(cap.cap_type).unwrap();
            let clone = self_cap_type.clone();
            let self_health = if clone.base_health > cap.dmg_taken {
                clone.base_health - cap.dmg_taken
            } else {
                0
            };
            
            if self_health < 5 {
                panic!("Not enough health, ability would kill self");
            }
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let (new_game, new_cap) = handle_damage(ref game, ref cap_at_target, 7);
            game = new_game;
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(new_cap));
            let (new_game, new_cap) = handle_damage(ref game, ref cap, 4);
            game = new_game;
            locations.insert(cap.id.into(), NullableTrait::new(new_cap));
        },
        21 => {
            // "Deal 8 damage to an enemy, but stun this unit next turn"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let (new_game, new_cap) = handle_damage(ref game, ref cap_at_target, 9);
            game = new_game;
            let stun_effect = Effect {
                game_id: game.id,
                effect_id: game.effect_ids.len().into(),
                effect_type: EffectType::Stun(1),
                target: EffectTarget::Cap(cap.id),
                remaining_triggers: 1,
            };
            new_effects.append(stun_effect);
            game.effect_ids.append(stun_effect.effect_id);
            locations.insert((target.x * 7 + target.y).into(), NullableTrait::new(new_cap));
        },
        22 => {
            // "Gain shield equal to target unit's shield"
            let mut cap_at_target = locations.get((target.x * 7 + target.y).into()).deref();
            let mut ally_shield = cap_at_target.shield_amt.try_into().unwrap();
           
            cap.shield_amt += ally_shield;
            locations.insert(cap.id.into(), NullableTrait::new(cap));
        },
        23 => {
            // "Heal all allies for 2 health"
            //todo
        //    game = handle_damage(ref game, self.id, ref world, 2 + extra_energy);
            
        },
        _ => panic!("Not yet implemented"),
    }



    (game.clone(), new_effects, locations)
}