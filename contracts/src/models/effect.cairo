use caps::models::game::{Vec2};

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
#[dojo::model]
pub struct Effect {
    #[key]
    pub game_id: u64,
    #[key]
    pub effect_id: u64,
    pub effect_type: EffectType,
    pub target: EffectTarget,
    pub remaining_triggers: u8,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum EffectType {
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
    Stun,
    Double,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum EffectTarget {
    Cap: u64,
    Square: Vec2,
}

#[generate_trait]
pub impl EffectImpl of EffectTrait {

    fn new(game_id: u64, effect_id: u64, effect_type: EffectType, target: EffectTarget, remaining_triggers: u8) -> Effect {
        Effect {
            game_id,
            effect_id,
            effect_type,
            target,
            remaining_triggers,
        }
    }

    fn trigger(ref self: Effect) {
        if self.remaining_triggers > 0 {
            self.remaining_triggers -= 1;
        }
    }

    fn get_timing(self: @Effect) -> Timing {
        match self.effect_type {
            EffectType::DamageBuff => Timing::MoveStep,
            EffectType::Shield => Timing::MoveStep,
            EffectType::Heal => Timing::StartOfTurn,
            EffectType::DOT => Timing::EndOfTurn,
            EffectType::MoveBonus => Timing::MoveStep,
            EffectType::AttackBonus => Timing::MoveStep,
            EffectType::BonusRange => Timing::MoveStep,
            EffectType::MoveDiscount => Timing::MoveStep,
            EffectType::AttackDiscount => Timing::MoveStep,
            EffectType::AbilityDiscount => Timing::MoveStep,
            EffectType::ExtraEnergy => Timing::StartOfTurn,
            EffectType::Stun => Timing::StartOfTurn,
            EffectType::Double => Timing::EndOfTurn,
        }
    }
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum Timing {
    StartOfTurn,
    MoveStep,
    EndOfTurn,
}
