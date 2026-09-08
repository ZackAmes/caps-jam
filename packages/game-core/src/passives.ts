import { pathDistance, type LayoutConfig } from './board';
import type { ChainCap, CapTypeDef, Passive, PassiveCondition, PassiveKind, Relation } from './types';
export const onBoard = (c: ChainCap) => !c.dead && c.x !== null && c.y !== null;
const related = (source: ChainCap, other: ChainCap, relation: Relation) => source.id !== other.id && onBoard(other) && (relation === 'Any' || (source.playerSlot === other.playerSlot) === (relation === 'Ally'));
const distance = (layout: LayoutConfig, a: ChainCap, b: ChainCap) => pathDistance(layout, [a.x!, a.y!], [b.x!, b.y!]);
export function conditionMet(condition: PassiveCondition, source: ChainCap, maxHealth: number, caps: ChainCap[], layout: LayoutConfig): boolean {
  if (!onBoard(source)) return false;
  switch (condition.kind) {
    case 'AlliesOnBoard': return caps.filter(c => onBoard(c) && c.playerSlot === source.playerSlot).length >= condition.value;
    case 'AllyWithin': case 'EnemyWithin': return caps.some(c => related(source, c, condition.kind === 'AllyWithin' ? 'Ally' : 'Enemy') && distance(layout, source, c) <= condition.value);
    case 'HealthBelowPercent': return source.health * 100 < maxHealth * condition.value;
    case 'OnEnemyHalf': return source.playerSlot === 0 ? source.y! > 2 : source.y! < 2;
    case 'PieceInRow': return caps.some(c => related(source, c, condition.relation) && c.y === source.y);
    case 'PieceInColumn': return caps.some(c => related(source, c, condition.relation) && c.x === source.x);
  }
}
export function passiveActive(passive: Passive, source: ChainCap, maxHealth: number, caps: ChainCap[], layout: LayoutConfig): boolean {
  return onBoard(source) && passive.conditions.every(c => conditionMet(c, source, maxHealth, caps, layout));
}
/** Pure derived state. Removing a source or changing any prerequisite removes its bonus immediately. */
export function passiveBonus(kind: PassiveKind, target: ChainCap, caps: ChainCap[], definitions: Map<number, CapTypeDef>, layout: LayoutConfig): number {
  if (!onBoard(target)) return 0;
  let bonus = 0;
  for (const source of caps) {
    const def = definitions.get(source.capType);
    if (!def) continue;
    for (const passive of def.passives) {
      if (passive.kind !== kind || !passiveActive(passive, source, def.maxHealth, caps, layout)) continue;
      const to = passive.target;
      const applies = to.kind === 'SelfCap' ? source.id === target.id : related(source, target, to.kind === 'AlliesWithin' ? 'Ally' : to.kind === 'EnemiesWithin' ? 'Enemy' : 'Any') && distance(layout, source, target) <= to.radius;
      if (applies) bonus = Math.min(65535, bonus + passive.amount);
    }
  }
  return bonus;
}
