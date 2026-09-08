import { test, expect } from 'bun:test';
import { greedyStrategy } from '../src/strategies/greedy';
import { getLayout } from '@caps/game-core/board';
import { previewTurn } from '@caps/game-core/preview';
import type { PositionV4 } from '../src/game/v4';
import type { ChainCap, CapTypeDef } from '@caps/game-core/types';

const cap = (id: number, slot: number, type: number, x: number | null, y: number | null): ChainCap => ({ id, playerSlot: slot, owner: slot ? '0x2' : '0x1', capType: type, setId: 0, x, y, health: 6, shield: 0, stunnedTurns: 0, availableTurn: 0, dead: false });
function position(caps: ChainCap[], slot = 0): PositionV4 {
  const definitions = new Map<number, CapTypeDef>([1,5].map(id => [id, { id, name: 'Test', description: '', maxHealth: 6, attack: 2, moveRange: 1, attackRange: 1, playCost: 0, moveCost: 0, abilityCost: 2, abilityDescription: '', abilityTarget: id === 5 ? 1 : 0, abilityRange: 0, passives: [] }]));
  return {
    game: { id: 1, player1: '0x1', player2: '0x2', layout: 1, setId: 0, turnCount: slot, over: false, winner: '0x0', winnerSlot: 2, energy: 3, p1Energy: 3, p2Energy: 3, caps, effectIds: [] },
    hand: { gameId: 1, playerSlot: slot, roster: caps.filter(c => c.playerSlot === slot).map(c => c.id), handSize: 4, window: caps.filter(c => c.playerSlot === slot && c.x === null).map(c => c.id) },
    definitions,
    layout: getLayout(1),
    stack: {gameId:1,nextId:0,entries:[]},
  };
}
const run = (p: PositionV4) => previewTurn(p.game, p.hand, p.definitions, p.layout, greedyStrategy.chooseTurn(p));
test('wins at either opponent back-row goal', () => {
  expect(run(position([cap(1,0,1,2,3)])).winnerSlot).toBe(0);
  expect(run(position([cap(2,1,1,2,1)],1)).winnerSlot).toBe(1);
});
test('uses Runner ability for a two-move win', () => {
  const p = position([cap(1,0,5,2,2)]);
  const actions = greedyStrategy.chooseTurn(p);
  expect(actions).toHaveLength(3); expect(actions.some(a => a.kind === 'Ability')).toBe(true);
  expect(run(p).winnerSlot).toBe(0);
});
test('deploys legally and deterministically from an opening hand', () => {
  const p = position([cap(1,0,1,null,null),cap(3,0,5,null,null)]);
  const actions = greedyStrategy.chooseTurn(p);
  expect(actions[0].kind).toBe('Play'); expect(greedyStrategy.chooseTurn(p)).toEqual(actions);
  expect(run(p).caps.some(c => c.x !== null)).toBe(true);
});
test('passes when no pieces can act', () => { expect(greedyStrategy.chooseTurn(position([]))).toEqual([]); });
test('blocks an immediate enemy goal with deployment', () => {
  const p = position([cap(1,0,1,null,null),cap(2,1,1,1,0)]);
  p.layout = getLayout(0);
  expect(greedyStrategy.chooseTurn(p)[0]).toEqual({ capId: 1, kind: 'Play', x: 2, y: 0 });
});

test('moves away from a lethal pending row instead of advancing into it', () => {
  const p = position([cap(2,1,1,0,0)],1);
  p.layout = getLayout(0);
  p.game.layout = 0;
  p.stack = {gameId:1,nextId:1,entries:[{id:1,sourceId:99,playerSlot:0,announcedTurn:0,readyTurn:2,impact:{kind:'Damage',selection:{kind:'Row',index:0},relation:'Any',amount:9}}]};
  expect(greedyStrategy.chooseTurn(p)).toEqual([{capId:2,kind:'Move',x:0,y:1}]);
});
