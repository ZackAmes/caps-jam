import type { Passive, PassiveCondition } from '@caps/game-core/types';
const names = { AttackBonus: 'attack', DamageReduction: 'damage reduction', AbilityRangeBonus: 'ability range (path steps)', EnergyGeneration: 'energy per owner turn', Regeneration: 'healing at owner turn end' };
export function conditionLabel(c: PassiveCondition): string {
  switch (c.kind) {
    case 'AlliesOnBoard': return `${c.value}+ friendly pieces on board (including self)`;
    case 'AllyWithin': return `another ally within ${c.value} path steps`;
    case 'EnemyWithin': return `an enemy within ${c.value} path steps`;
    case 'HealthBelowPercent': return `health below ${c.value}%`;
    case 'OnEnemyHalf': return 'on the enemy half';
    case 'PieceInRow': case 'PieceInColumn': return `another ${c.relation === 'Ally' ? 'friendly' : c.relation === 'Enemy' ? 'enemy' : ''} piece in the same ${c.kind === 'PieceInRow' ? 'row' : 'column'}`;
  }
}
export function passiveLabel(p: Passive): string {
  const target = p.target.kind === 'SelfCap' ? 'self' : `${p.target.kind === 'AlliesWithin' ? 'other allies' : p.target.kind === 'EnemiesWithin' ? 'enemies' : 'other pieces'} within ${p.target.radius} path steps`;
  return `+${p.amount} ${names[p.kind]} for ${target} while on board${p.conditions.length ? ' and ' + p.conditions.map(conditionLabel).join(' and ') : ''}`;
}
