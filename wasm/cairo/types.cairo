
pub fn main(cap_type: u16) -> Option<CapType> {
    let res = match cap_type {
        0 => Option::Some(
            CapType {
                id: 0,
                name: "Red Tower",
                description: "Red Tower",
                move_cost: 1,
                attack_cost: 1,
                attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
                ability_range: array![
                    Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 },
                ],
                ability_description: "None",
                move_range: Vec2 { x: 1, y: 1 },
                attack_dmg: 1,
                base_health: 10,
                ability_target: TargetType::None,
                ability_cost: 0,
            },
        ),
        1 => Option::Some(
            CapType {
                id: 1,
                name: "Blue Tower",
                description: "Blue Tower",
                move_cost: 1,
                attack_cost: 1,
                attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
                ability_range: array![
                    Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 },
                ],
                ability_description: "None",
                move_range: Vec2 { x: 1, y: 1 },
                attack_dmg: 1,
                base_health: 10,
                ability_target: TargetType::None,
                ability_cost: 0,
            },
        ),
        2 => Option::Some(
            CapType {
                id: 2,
                name: "Yellow Tower",
                description: "Yellow Tower",
                move_cost: 1,
                attack_cost: 1,
                attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
                ability_range: array![
                    Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 },
                ],
                ability_description: "None",
                move_range: Vec2 { x: 1, y: 1 },
                attack_dmg: 1,
                base_health: 10,
                ability_target: TargetType::None,
                ability_cost: 0,
            },
        ),
        3 => Option::Some(
            CapType {
                id: 3,
                name: "Green Tower",
                description: "Green Tower",
                move_cost: 1,
                attack_cost: 1,
                attack_range: array![Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 }],
                ability_range: array![
                    Vec2 { x: 1, y: 0 }, Vec2 { x: 0, y: 1 }, Vec2 { x: 1, y: 1 },
                ],
                ability_description: "None",
                move_range: Vec2 { x: 1, y: 1 },
                attack_dmg: 1,
                base_health: 10,
                ability_target: TargetType::None,
                ability_cost: 0,
            },
        ),
        4 => Option::Some(
            CapType {
                id: 4,
                name: "Red Basic",
                description: "Cap 3",
                move_cost: 1,
                attack_cost: 1,
                attack_range: array![
                    Vec2 { x: 0, y: 1 },
                    Vec2 { x: 0, y: 2 },
                    Vec2 { x: 1, y: 1 },
                    Vec2 { x: 1, y: 0 },
                ],
                ability_range: array![
                    Vec2 { x: 1, y: 0 },
                    Vec2 { x: 0, y: 1 },
                    Vec2 { x: 0, y: 2 },
                    Vec2 { x: 1, y: 1 },
                ],
                ability_description: "Deal 4 damage to an enemy",
                move_range: Vec2 { x: 1, y: 2 },
                attack_dmg: 2,
                base_health: 8,
                ability_target: TargetType::OpponentCap,
                ability_cost: 2,
            },
        ),
        _ => Option::None,
    };
    res
}

#[derive(Drop, Serde, Debug, Clone)]
pub struct CapType {
    pub id: u16,
    pub name: ByteArray,
    pub description: ByteArray,
    pub move_cost: u8,
    pub attack_cost: u8,
    pub attack_range: Array<Vec2>,
    pub ability_range: Array<Vec2>,
    pub ability_description: ByteArray,
    pub move_range: Vec2,
    pub attack_dmg: u16,
    pub base_health: u16,
    pub ability_target: TargetType,
    pub ability_cost: u8,
}

#[derive(Copy, Drop, Serde, PartialEq, Debug)]
pub struct Vec2 {
    pub x: u8,
    pub y: u8,
}

#[derive(Copy, Drop, Serde, Debug, PartialEq)]
pub enum TargetType {
    None,
    SelfCap,
    TeamCap,
    OpponentCap,
    AnyCap,
    AnySquare,
}

