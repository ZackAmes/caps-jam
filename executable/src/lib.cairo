#[executable]
fn main(location: Location) -> Location {
    location
}

#[derive(Drop, Serde, Copy)]
enum Location {
    Bench,
    Board: Vec2,
    Dead,
}

#[derive(Drop, Serde, Copy)]
struct Vec2 {
    x: u8,
    y: u8,
}
