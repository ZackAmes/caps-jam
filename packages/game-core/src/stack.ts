import { pathDistance, type LayoutConfig } from './board';
import { passiveBonus, onBoard } from './passives';
import type { AbilityStack, StackEntry, DelayedImpact, ChainCap, CapTypeDef } from './types';
/** Copy values explicitly so reactive Proxy inputs work without sharing mutable state. */
function copyImpact(impact: DelayedImpact): DelayedImpact {
  return { ...impact, selection: { ...impact.selection } };
}
export function copyStack(stack: AbilityStack): AbilityStack {
  return { ...stack, entries: stack.entries.map(entry => ({ ...entry, impact: copyImpact(entry.impact) })) };
}
export function schedule(stack: AbilityStack, sourceId: number, playerSlot: number, turn: number, delay: number, impact: DelayedImpact, layout: LayoutConfig): void {
  if (!Number.isInteger(delay) || delay < 1 || delay > 8) throw new Error('Delay must be 1 to 8');
  if (stack.entries.length >= 32) throw new Error('Ability stack is full');
  if (!Number.isInteger(impact.amount) || impact.amount < 1 || impact.amount > 65535) throw new Error('Invalid delayed amount');
  const target = impact.selection;
  if ((target.kind === 'Row' || target.kind === 'Column') && (!Number.isInteger(target.index) || target.index < 0 || target.index >= (target.kind === 'Row' ? layout.height : layout.width))) throw new Error('Invalid line');
  if (target.kind === 'Within' && (!layout.isWalkable(target.x, target.y) || !Number.isInteger(target.radius) || target.radius < 0 || target.radius > 24)) throw new Error('Invalid zone');
  if (target.kind === 'Piece' && (!Number.isSafeInteger(target.id) || target.id < 1)) throw new Error('Invalid piece target');
  stack.entries.push({ id: ++stack.nextId, sourceId, playerSlot, announcedTurn: turn, readyTurn: turn + delay + 1, impact: copyImpact(impact) });
}
export function counterPending(stack: AbilityStack, id: number): void { stack.entries = stack.entries.filter(e => e.id !== id); }
export function popReady(stack: AbilityStack, boundary: number): StackEntry | null {
  const top = stack.entries.at(-1);
  return top && top.readyTurn <= boundary ? stack.entries.pop()! : null;
}
export function selectedBy(entry: StackEntry, cap: ChainCap, layout: LayoutConfig): boolean {
  if (!onBoard(cap)) return false;
  const relation = entry.impact.relation;
  if (relation !== 'Any' && ((cap.playerSlot === entry.playerSlot) !== (relation === 'Ally'))) return false;
  const target = entry.impact.selection;
  switch (target.kind) {
    case 'Piece': return cap.id === target.id;
    case 'Row': return cap.y === target.index;
    case 'Column': return cap.x === target.index;
    case 'Within': return pathDistance(layout, [target.x,target.y], [cap.x!,cap.y!]) <= target.radius;
  }
}
/** Resolves one simultaneous impact. The caller resolves captures/victory between entries. */
export function resolveImpact(entry: StackEntry, caps: ChainCap[], definitions: Map<number, CapTypeDef>, layout: LayoutConfig): ChainCap[] {
  return caps.map(cap => {
    const c = {...cap};
    if (!selectedBy(entry, c, layout)) return c;
    const amount = entry.impact.amount;
    if (entry.impact.kind === 'Damage') {
      const reduced = Math.max(0, amount - passiveBonus('DamageReduction', cap, caps, definitions, layout));
      const absorbed = Math.min(c.shield, reduced);
      c.shield -= absorbed; c.health = Math.max(0, c.health - reduced + absorbed);
      if (c.health === 0) { c.dead = true; c.x = null; c.y = null; }
    } else if (entry.impact.kind === 'Heal') c.health = Math.min(definitions.get(c.capType)?.maxHealth ?? c.health, c.health + amount);
    else c.shield = Math.min(65535, c.shield + amount);
    return c;
  });
}
export function describeImpact(entry: StackEntry): string {
  const p = entry.impact, t = p.selection;
  const area = t.kind === 'Row' ? `row ${t.index + 1}` : t.kind === 'Column' ? `column ${t.index + 1}` : t.kind === 'Piece' ? `piece #${t.id}` : `within ${t.radius} steps of (${t.x}, ${t.y})`;
  const side = p.relation === 'Any' ? 'all pieces' : p.relation === 'Ally' ? `P${entry.playerSlot + 1} pieces` : `P${2 - entry.playerSlot} pieces`;
  return `${p.kind} ${p.amount} · ${side} · ${area}`;
}

/** Forecast the stack only; normal end-turn effects/income remain the caller's responsibility. */
export function resolveReadyStack(pending: AbilityStack, board: ChainCap[], definitions: Map<number, CapTypeDef>, layout: LayoutConfig, boundary: number) {
  const stack = copyStack(pending);
  let caps = board.map(c => ({...c}));
  const resolved: number[] = [];
  for (let entry = popReady(stack, boundary); entry; entry = popReady(stack, boundary)) {
    caps = resolveImpact(entry, caps, definitions, layout); resolved.push(entry.id);
  }
  return {stack, caps, resolved};
}
