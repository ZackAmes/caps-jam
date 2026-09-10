/// Separate storage keeps existing Game records compatible with the clock upgrade.
#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct GameClock {
    #[key]
    pub game_id: u64,
    pub enabled: bool,
    pub p1_seconds: u64,
    pub p2_seconds: u64,
    pub running_since: u64,
    /// 2 while no timeout has occurred, otherwise the losing side (0/1).
    pub timed_out_slot: u8,
}

pub fn fresh(game_id: u64, now: u64) -> GameClock {
    GameClock {
        game_id,
        enabled: true,
        p1_seconds: 120,
        p2_seconds: 120,
        running_since: now,
        timed_out_slot: 2,
    }
}

pub fn remaining(clock: GameClock, slot: u8, now: u64) -> u64 {
    let budget = if slot == 0 {
        clock.p1_seconds
    } else {
        clock.p2_seconds
    };
    let elapsed = if now > clock.running_since {
        now - clock.running_since
    } else {
        0
    };
    if elapsed >= budget {
        0
    } else {
        budget - elapsed
    }
}

pub fn finish_turn(ref clock: GameClock, slot: u8, now: u64, increment: bool) {
    let time = remaining(clock, slot, now) + if increment {
        10
    } else {
        0
    };
    if slot == 0 {
        clock.p1_seconds = time;
    } else {
        clock.p2_seconds = time;
    }
    clock.running_since = now;
}
