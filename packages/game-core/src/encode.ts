import type { TurnAction } from './types';
const ACTION_VARIANT = { Play: 0, Move: 1, Ability: 2 } as const;
export function encodeActions(actions: TurnAction[]): number[] {
  return [actions.length, ...actions.flatMap(a => a.kind === 'StackAbility'
    ? [a.capId, 3, a.targetId] : [a.capId, ACTION_VARIANT[a.kind], a.x, a.y])];
}
