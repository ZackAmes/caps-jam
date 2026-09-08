import type { TurnAction } from './types';
const ACTION_VARIANT: Record<TurnAction['kind'], number> = { Play: 0, Move: 1, Ability: 2 };
export function encodeActions(actions: TurnAction[]): number[] {
  return [actions.length, ...actions.flatMap(a => [a.capId, ACTION_VARIANT[a.kind], a.x, a.y])];
}
