pub mod systems {
    pub mod actions;
}

pub mod models {
    pub mod cap;
    pub mod effect;
    pub mod game;
    pub mod set;
    pub mod set_data;
}

pub mod sets {
    pub mod set_zero;
}

pub mod logic {
    pub mod board_data;
    pub mod hand;
    pub mod ops;
    pub mod passives;
    pub mod rules;
    pub mod track;
}

#[cfg(test)]
mod tests {
    mod foundation_test;
    mod rules_test;
}
