use caps::logic::board_data::distances;
use caps::models::game::Vec2;

pub const LAYOUT_PERIMETER_5X5: u8 = 0;
pub const LAYOUT_CROSS_5X5: u8 = 1;
pub const LAYOUT_DIAGONAL_X_5X5: u8 = 2;
pub const LAYOUT_DIAMOND_5X5: u8 = 3;
pub const MAX_BOARD_SIZE: u8 = 5;

pub fn get_board_dimensions(layout: u8) -> (u8, u8) {
    (5, 5)
}

/// Shortest number of explicit path edges. Occupancy does not change geometric range.
pub fn path_distance(layout: u8, from: Vec2, to: Vec2) -> Option<u8> {
    if layout > 3 || from.x >= 5 || from.y >= 5 || to.x >= 5 || to.y >= 5 {
        return Option::None;
    }
    let row = distances(layout, from.y * 5 + from.x);
    let distance = *row.at((to.y * 5 + to.x).into());
    if distance == 255 {
        Option::None
    } else {
        Option::Some(distance)
    }
}
pub fn is_walkable(layout: u8, pos: Vec2) -> bool {
    path_distance(layout, pos, pos).is_some()
}
pub fn is_valid_step(layout: u8, from: Vec2, to: Vec2) -> bool {
    path_distance(layout, from, to) == Option::Some(1)
}
pub fn within_range(layout: u8, from: Vec2, to: Vec2, range: u16) -> bool {
    match path_distance(layout, from, to) {
        Option::Some(n) => n.into() <= range,
        Option::None => false,
    }
}
pub fn get_p1_deploy_spot(layout: u8) -> Vec2 {
    Vec2 { x: 2, y: 0 }
}
pub fn get_p2_deploy_spot(layout: u8) -> Vec2 {
    Vec2 { x: 2, y: 4 }
}
pub fn get_walkable_neighbors(layout: u8, pos: Vec2) -> Array<Vec2> {
    let mut result = array![];
    if pos.x >= 5 || pos.y >= 5 {
        return result;
    }
    let row = distances(layout, pos.y * 5 + pos.x);
    let mut id: u8 = 0;
    while id < 25 {
        if *row.at(id.into()) == 1 {
            result.append(Vec2 { x: id % 5, y: id / 5 });
        }
        id += 1;
    }
    result
}
