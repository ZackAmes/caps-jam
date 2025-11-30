use caps_core::types::game::{Vec2};

#[derive(Copy, Drop, Serde, PartialEq)]
pub struct Effect {
    pub game_id: u64,
    pub effect_id: u64,
    pub effect_type: EffectType,
    pub target: EffectTarget,
    pub remaining_triggers: u8,
}

#[derive(Copy, Drop, Serde, PartialEq)]
pub enum EffectType {
    None,
    DamageBuff: u8,
    Shield: u8,
    Heal: u8,
    DOT: u8,
    MoveBonus: u8,
    AttackBonus: u8,
    BonusRange: u8,
    MoveDiscount: u8,
    AttackDiscount: u8,
    AbilityDiscount: u8,
    ExtraEnergy: u8,
    Stun: u8,
    Double: u8,
}

#[derive(Copy, Drop, Serde, PartialEq)]
pub enum EffectTarget {
    None,
    Cap: u64,
    Square: Vec2,
}

#[generate_trait]
pub impl EffectImpl of EffectTrait {
    fn new(
        game_id: u64,
        effect_id: u64,
        effect_type: EffectType,
        target: EffectTarget,
        remaining_triggers: u8,
    ) -> Effect {
        Effect { game_id, effect_id, effect_type, target, remaining_triggers }
    }

    fn trigger(ref self: Effect) {
        if self.remaining_triggers > 0 {
            self.remaining_triggers -= 1;
        }
    }

    fn get_timing(self: @Effect) -> Timing {
        match self.effect_type {
            EffectType::None => Timing::StartOfTurn,
            EffectType::DamageBuff(_) => Timing::MoveStep,
            EffectType::Shield(_) => Timing::MoveStep,
            EffectType::Heal(_) => Timing::StartOfTurn,
            EffectType::DOT(_) => Timing::EndOfTurn,
            EffectType::MoveBonus(_) => Timing::MoveStep,
            EffectType::AttackBonus(_) => Timing::MoveStep,
            EffectType::BonusRange(_) => Timing::MoveStep,
            EffectType::MoveDiscount(_) => Timing::MoveStep,
            EffectType::AttackDiscount(_) => Timing::MoveStep,
            EffectType::AbilityDiscount(_) => Timing::MoveStep,
            EffectType::ExtraEnergy(_) => Timing::StartOfTurn,
            EffectType::Stun(_) => Timing::StartOfTurn,
            EffectType::Double(_) => Timing::EndOfTurn,
        }
    }
}

#[derive(Copy, Drop, Serde, PartialEq)]
pub enum Timing {
    StartOfTurn,
    MoveStep,
    EndOfTurn,
}
