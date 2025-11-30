// Bidirectional conversions using Into trait
use core::dict::Felt252Dict;

// ============= Vec2 conversions =============

pub impl Vec2IntoCore of Into<caps::models::game::Vec2, caps_core::types::game::Vec2> {
    fn into(self: caps::models::game::Vec2) -> caps_core::types::game::Vec2 {
        caps_core::types::game::Vec2 { x: self.x, y: self.y }
    }
}

pub impl Vec2FromCore of Into<caps_core::types::game::Vec2, caps::models::game::Vec2> {
    fn into(self: caps_core::types::game::Vec2) -> caps::models::game::Vec2 {
        caps::models::game::Vec2 { x: self.x, y: self.y }
    }
}

// ============= ActionType conversions =============

pub impl ActionTypeIntoCore of Into<caps::models::game::ActionType, caps_core::types::game::ActionType> {
    fn into(self: caps::models::game::ActionType) -> caps_core::types::game::ActionType {
        match self {
            caps::models::game::ActionType::Play(v) => caps_core::types::game::ActionType::Play(v.into()),
            caps::models::game::ActionType::Move(v) => caps_core::types::game::ActionType::Move(v.into()),
            caps::models::game::ActionType::Attack(v) => caps_core::types::game::ActionType::Attack(v.into()),
            caps::models::game::ActionType::Ability(v) => caps_core::types::game::ActionType::Ability(v.into()),
        }
    }
}

pub impl ActionTypeFromCore of Into<caps_core::types::game::ActionType, caps::models::game::ActionType> {
    fn into(self: caps_core::types::game::ActionType) -> caps::models::game::ActionType {
        match self {
            caps_core::types::game::ActionType::Play(v) => caps::models::game::ActionType::Play(v.into()),
            caps_core::types::game::ActionType::Move(v) => caps::models::game::ActionType::Move(v.into()),
            caps_core::types::game::ActionType::Attack(v) => caps::models::game::ActionType::Attack(v.into()),
            caps_core::types::game::ActionType::Ability(v) => caps::models::game::ActionType::Ability(v.into()),
        }
    }
}

// ============= Action conversions =============

pub impl ActionIntoCore of Into<caps::models::game::Action, caps_core::types::game::Action> {
    fn into(self: caps::models::game::Action) -> caps_core::types::game::Action {
        caps_core::types::game::Action {
            cap_id: self.cap_id,
            action_type: self.action_type.into(),
        }
    }
}

pub impl ActionFromCore of Into<caps_core::types::game::Action, caps::models::game::Action> {
    fn into(self: caps_core::types::game::Action) -> caps::models::game::Action {
        caps::models::game::Action {
            cap_id: self.cap_id,
            action_type: self.action_type.into(),
        }
    }
}

// ============= Game conversions =============

pub impl GameIntoCore of Into<caps::models::game::Game, caps_core::types::game::Game> {
    fn into(self: caps::models::game::Game) -> caps_core::types::game::Game {
        caps_core::types::game::Game {
            id: self.id,
            player1: self.player1,
            player2: self.player2,
            caps_ids: self.caps_ids,
            turn_count: self.turn_count,
            over: self.over,
            effect_ids: self.effect_ids,
            last_action_timestamp: self.last_action_timestamp,
        }
    }
}

pub impl GameFromCore of Into<caps_core::types::game::Game, caps::models::game::Game> {
    fn into(self: caps_core::types::game::Game) -> caps::models::game::Game {
        caps::models::game::Game {
            id: self.id,
            player1: self.player1,
            player2: self.player2,
            caps_ids: self.caps_ids,
            turn_count: self.turn_count,
            over: self.over,
            effect_ids: self.effect_ids,
            last_action_timestamp: self.last_action_timestamp,
        }
    }
}

// ============= Cap conversions =============

pub impl CapIntoCore of Into<caps::models::cap::Cap, caps_core::types::cap::Cap> {
    fn into(self: caps::models::cap::Cap) -> caps_core::types::cap::Cap {
        caps_core::types::cap::Cap {
            id: self.id,
            owner: self.owner,
            location: self.location.into(),
            set_id: self.set_id,
            cap_type: self.cap_type,
            dmg_taken: self.dmg_taken,
            shield_amt: self.shield_amt,
        }
    }
}

pub impl CapFromCore of Into<caps_core::types::cap::Cap, caps::models::cap::Cap> {
    fn into(self: caps_core::types::cap::Cap) -> caps::models::cap::Cap {
        caps::models::cap::Cap {
            id: self.id,
            owner: self.owner,
            location: self.location.into(),
            set_id: self.set_id,
            cap_type: self.cap_type,
            dmg_taken: self.dmg_taken,
            shield_amt: self.shield_amt,
        }
    }
}

// ============= Location conversions =============

pub impl LocationIntoCore of Into<caps::models::cap::Location, caps_core::types::cap::Location> {
    fn into(self: caps::models::cap::Location) -> caps_core::types::cap::Location {
        match self {
            caps::models::cap::Location::Bench => caps_core::types::cap::Location::Bench,
            caps::models::cap::Location::Board(v) => caps_core::types::cap::Location::Board(
                caps_core::types::game::Vec2 { x: v.x, y: v.y },
            ),
            caps::models::cap::Location::Hidden(h) => caps_core::types::cap::Location::Hidden(h),
            caps::models::cap::Location::Dead => caps_core::types::cap::Location::Dead,
        }
    }
}

pub impl LocationFromCore of Into<caps_core::types::cap::Location, caps::models::cap::Location> {
    fn into(self: caps_core::types::cap::Location) -> caps::models::cap::Location {
        match self {
            caps_core::types::cap::Location::Bench => caps::models::cap::Location::Bench,
            caps_core::types::cap::Location::Board(v) => caps::models::cap::Location::Board(
                caps::models::game::Vec2 { x: v.x, y: v.y },
            ),
            caps_core::types::cap::Location::Hidden(h) => caps::models::cap::Location::Hidden(h),
            caps_core::types::cap::Location::Dead => caps::models::cap::Location::Dead,
        }
    }
}

// ============= TargetType conversions =============

pub impl TargetTypeIntoCore of Into<caps::models::cap::TargetType, caps_core::types::cap::TargetType> {
    fn into(self: caps::models::cap::TargetType) -> caps_core::types::cap::TargetType {
        match self {
            caps::models::cap::TargetType::None => caps_core::types::cap::TargetType::None,
            caps::models::cap::TargetType::SelfCap => caps_core::types::cap::TargetType::SelfCap,
            caps::models::cap::TargetType::TeamCap => caps_core::types::cap::TargetType::TeamCap,
            caps::models::cap::TargetType::OpponentCap => caps_core::types::cap::TargetType::OpponentCap,
            caps::models::cap::TargetType::AnyCap => caps_core::types::cap::TargetType::AnyCap,
            caps::models::cap::TargetType::AnySquare => caps_core::types::cap::TargetType::AnySquare,
        }
    }
}

pub impl TargetTypeFromCore of Into<caps_core::types::cap::TargetType, caps::models::cap::TargetType> {
    fn into(self: caps_core::types::cap::TargetType) -> caps::models::cap::TargetType {
        match self {
            caps_core::types::cap::TargetType::None => caps::models::cap::TargetType::None,
            caps_core::types::cap::TargetType::SelfCap => caps::models::cap::TargetType::SelfCap,
            caps_core::types::cap::TargetType::TeamCap => caps::models::cap::TargetType::TeamCap,
            caps_core::types::cap::TargetType::OpponentCap => caps::models::cap::TargetType::OpponentCap,
            caps_core::types::cap::TargetType::AnyCap => caps::models::cap::TargetType::AnyCap,
            caps_core::types::cap::TargetType::AnySquare => caps::models::cap::TargetType::AnySquare,
        }
    }
}

// ============= Effect conversions =============

pub impl EffectTypeIntoCore of Into<caps::models::effect::EffectType, caps_core::types::effect::EffectType> {
    fn into(self: caps::models::effect::EffectType) -> caps_core::types::effect::EffectType {
        match self {
            caps::models::effect::EffectType::None => caps_core::types::effect::EffectType::None,
            caps::models::effect::EffectType::DamageBuff(v) => caps_core::types::effect::EffectType::DamageBuff(v),
            caps::models::effect::EffectType::Shield(v) => caps_core::types::effect::EffectType::Shield(v),
            caps::models::effect::EffectType::Heal(v) => caps_core::types::effect::EffectType::Heal(v),
            caps::models::effect::EffectType::DOT(v) => caps_core::types::effect::EffectType::DOT(v),
            caps::models::effect::EffectType::MoveBonus(v) => caps_core::types::effect::EffectType::MoveBonus(v),
            caps::models::effect::EffectType::AttackBonus(v) => caps_core::types::effect::EffectType::AttackBonus(v),
            caps::models::effect::EffectType::BonusRange(v) => caps_core::types::effect::EffectType::BonusRange(v),
            caps::models::effect::EffectType::MoveDiscount(v) => caps_core::types::effect::EffectType::MoveDiscount(v),
            caps::models::effect::EffectType::AttackDiscount(v) => caps_core::types::effect::EffectType::AttackDiscount(v),
            caps::models::effect::EffectType::AbilityDiscount(v) => caps_core::types::effect::EffectType::AbilityDiscount(v),
            caps::models::effect::EffectType::ExtraEnergy(v) => caps_core::types::effect::EffectType::ExtraEnergy(v),
            caps::models::effect::EffectType::Stun(v) => caps_core::types::effect::EffectType::Stun(v),
            caps::models::effect::EffectType::Double(v) => caps_core::types::effect::EffectType::Double(v),
        }
    }
}

pub impl EffectTypeFromCore of Into<caps_core::types::effect::EffectType, caps::models::effect::EffectType> {
    fn into(self: caps_core::types::effect::EffectType) -> caps::models::effect::EffectType {
        match self {
            caps_core::types::effect::EffectType::None => caps::models::effect::EffectType::None,
            caps_core::types::effect::EffectType::DamageBuff(v) => caps::models::effect::EffectType::DamageBuff(v),
            caps_core::types::effect::EffectType::Shield(v) => caps::models::effect::EffectType::Shield(v),
            caps_core::types::effect::EffectType::Heal(v) => caps::models::effect::EffectType::Heal(v),
            caps_core::types::effect::EffectType::DOT(v) => caps::models::effect::EffectType::DOT(v),
            caps_core::types::effect::EffectType::MoveBonus(v) => caps::models::effect::EffectType::MoveBonus(v),
            caps_core::types::effect::EffectType::AttackBonus(v) => caps::models::effect::EffectType::AttackBonus(v),
            caps_core::types::effect::EffectType::BonusRange(v) => caps::models::effect::EffectType::BonusRange(v),
            caps_core::types::effect::EffectType::MoveDiscount(v) => caps::models::effect::EffectType::MoveDiscount(v),
            caps_core::types::effect::EffectType::AttackDiscount(v) => caps::models::effect::EffectType::AttackDiscount(v),
            caps_core::types::effect::EffectType::AbilityDiscount(v) => caps::models::effect::EffectType::AbilityDiscount(v),
            caps_core::types::effect::EffectType::ExtraEnergy(v) => caps::models::effect::EffectType::ExtraEnergy(v),
            caps_core::types::effect::EffectType::Stun(v) => caps::models::effect::EffectType::Stun(v),
            caps_core::types::effect::EffectType::Double(v) => caps::models::effect::EffectType::Double(v),
        }
    }
}

pub impl EffectTargetIntoCore of Into<caps::models::effect::EffectTarget, caps_core::types::effect::EffectTarget> {
    fn into(self: caps::models::effect::EffectTarget) -> caps_core::types::effect::EffectTarget {
        match self {
            caps::models::effect::EffectTarget::None => caps_core::types::effect::EffectTarget::None,
            caps::models::effect::EffectTarget::Cap(id) => caps_core::types::effect::EffectTarget::Cap(id),
            caps::models::effect::EffectTarget::Square(v) => caps_core::types::effect::EffectTarget::Square(
                caps_core::types::game::Vec2 { x: v.x, y: v.y }
            ),
        }
    }
}

pub impl EffectTargetFromCore of Into<caps_core::types::effect::EffectTarget, caps::models::effect::EffectTarget> {
    fn into(self: caps_core::types::effect::EffectTarget) -> caps::models::effect::EffectTarget {
        match self {
            caps_core::types::effect::EffectTarget::None => caps::models::effect::EffectTarget::None,
            caps_core::types::effect::EffectTarget::Cap(id) => caps::models::effect::EffectTarget::Cap(id),
            caps_core::types::effect::EffectTarget::Square(v) => caps::models::effect::EffectTarget::Square(
                caps::models::game::Vec2 { x: v.x, y: v.y }
            ),
        }
    }
}

pub impl EffectIntoCore of Into<caps::models::effect::Effect, caps_core::types::effect::Effect> {
    fn into(self: caps::models::effect::Effect) -> caps_core::types::effect::Effect {
        caps_core::types::effect::Effect {
            game_id: self.game_id,
            effect_id: self.effect_id,
            effect_type: self.effect_type.into(),
            target: self.target.into(),
            remaining_triggers: self.remaining_triggers,
        }
    }
}

pub impl EffectFromCore of Into<caps_core::types::effect::Effect, caps::models::effect::Effect> {
    fn into(self: caps_core::types::effect::Effect) -> caps::models::effect::Effect {
        caps::models::effect::Effect {
            game_id: self.game_id,
            effect_id: self.effect_id,
            effect_type: self.effect_type.into(),
            target: self.target.into(),
            remaining_triggers: self.remaining_triggers,
        }
    }
}

// ============= Array conversions =============

pub fn caps_array_into_core(arr: Array<caps::models::cap::Cap>) -> Array<caps_core::types::cap::Cap> {
    let mut result = ArrayTrait::new();
    for cap in arr {
        result.append(cap.into());
    };
    result
}

pub fn caps_array_from_core(
    arr: Array<caps_core::types::cap::Cap>,
) -> Array<caps::models::cap::Cap> {
    let mut result = ArrayTrait::new();
    for cap in arr {
        result.append(cap.into());
    };
    result
}

pub fn effects_array_into_core(
    arr: Array<caps::models::effect::Effect>,
) -> Array<caps_core::types::effect::Effect> {
    let mut result = ArrayTrait::new();
    for effect in arr {
        result.append(effect.into());
    };
    result
}

pub fn effects_array_from_core(
    arr: Array<caps_core::types::effect::Effect>,
) -> Array<caps::models::effect::Effect> {
    let mut result = ArrayTrait::new();
    for effect in arr {
        result.append(effect.into());
    };
    result
}

pub fn actions_array_into_core(
    arr: Array<caps::models::game::Action>,
) -> Array<caps_core::types::game::Action> {
    let mut result = ArrayTrait::new();
    for action in arr {
        result.append(action.into());
    };
    result
}

pub fn actions_array_from_core(
    arr: Array<caps_core::types::game::Action>,
) -> Array<caps::models::game::Action> {
    let mut result = ArrayTrait::new();
    for action in arr {
        result.append(action.into());
    };
    result
}

// ============= Dict conversions =============

pub fn caps_dict_from_core(
    ref core_dict: Felt252Dict<Nullable<caps_core::types::cap::Cap>>,
    cap_ids: @Array<u64>,
) -> Felt252Dict<Nullable<caps::models::cap::Cap>> {
    let mut result: Felt252Dict<Nullable<caps::models::cap::Cap>> = Default::default();
    let mut i = 0;
    while i < cap_ids.len() {
        let cap_id = *cap_ids[i];
        let core_cap = core_dict.get(cap_id.into()).deref();
        let contract_cap: caps::models::cap::Cap = core_cap.into();
        result.insert(cap_id.into(), NullableTrait::new(contract_cap));
        i += 1;
    };
    result
}

pub fn caps_dict_into_core(
    ref contract_dict: Felt252Dict<Nullable<caps::models::cap::Cap>>,
    cap_ids: @Array<u64>,
) -> Felt252Dict<Nullable<caps_core::types::cap::Cap>> {
    let mut result: Felt252Dict<Nullable<caps_core::types::cap::Cap>> = Default::default();
    let mut i = 0;
    while i < cap_ids.len() {
        let cap_id = *cap_ids[i];
        let contract_cap = contract_dict.get(cap_id.into()).deref();
        let core_cap: caps_core::types::cap::Cap = contract_cap.into();
        result.insert(cap_id.into(), NullableTrait::new(core_cap));
        i += 1;
    };
    result
}
