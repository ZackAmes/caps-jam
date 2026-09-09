import { test } from 'node:test';
import assert from 'node:assert/strict';
import { viewerSlot, pathEdges, effectTiming } from '../src/lib/game/presentation';
import { getLayout } from '@caps/game-core/board';
import type { ChainGame, AbilityStack, StackEntry } from '@caps/game-core/types';

test('viewer remains P1 during the bot turn; solo follows the active side', () => {
    const game = { player1: '0x01', player2: '0x02', turnCount: 1 } as ChainGame;
    assert.equal(viewerSlot(game, '0x1'), 0);
    assert.equal(viewerSlot(game, '0x2'), 1);
    assert.equal(viewerSlot(game, '0x3'), null);
    assert.equal(viewerSlot({...game, player2: '0x1'}, '0x01'), 1);
});
test('path overlay draws each legal edge once and excludes corner shortcuts', () => {
    for (const id of [0, 1, 2, 3]) {
        const layout = getLayout(id), edges = pathEdges(layout);
        for (let y = 0; y < 5; y++) for (let x = 0; x < 5; x++) {
            for (const [nx, ny] of layout.neighbors([x, y])) {
                assert.equal(edges.filter(e => e.x1 === x && e.y1 === y && e.x2 === nx && e.y2 === ny || e.x2 === x && e.y2 === y && e.x1 === nx && e.y1 === ny).length, 1);
            }
        }
        assert.equal(edges.some(e => e.x1 === 1 && e.y1 === 0 && e.x2 === 0 && e.y2 === 1), false);
    }
});
test('effect timing describes the response turn and blocked ready effects', () => {
    const first = { id: 1, readyTurn: 2 } as StackEntry;
    const second = { id: 2, readyTurn: 3 } as StackEntry;
    const stack: AbilityStack = { gameId: 1, nextId: 2, entries: [first, second] };
    assert.equal(effectTiming(first, {...stack, entries: [first]}, 0, 0), 'Ready after your opponent’s next turn');
    assert.equal(effectTiming(first, stack, 1, 1), 'Ready · waiting for newer effects above it');
    assert.equal(effectTiming(second, stack, 2, 0), 'Resolves when this turn ends');
});

test('stack boundary accounts for a newer long delay and footprint follows graph distance', async () => {
    const { resolutionBoundary, impactFootprint } = await import('../src/lib/game/presentation');
    const first = {id:1,readyTurn:2,impact:{kind:'Damage',selection:{kind:'Within',x:1,y:0,radius:1},relation:'Any',amount:4}} as StackEntry;
    const second = {id:2,readyTurn:5} as StackEntry;
    assert.equal(resolutionBoundary(first,{gameId:1,nextId:2,entries:[first,second]},1),5);
    const cells = impactFootprint(first,[],getLayout(0));
    assert.equal(cells.has('0,0'),true);assert.equal(cells.has('0,1'),false);
});

test('both players see their base at the bottom and orientation preserves canonical coordinates', async () => {
 const {boardPosition} = await import('../src/lib/game/presentation');
 const {LAYOUTS} = await import('@caps/game-core/board');
 for (const layout of Object.values(LAYOUTS)) for (const slot of [0,1]) {
  const own = slot === 0 ? layout.p1Deploy : layout.p2Deploy;
  assert.equal(boardPosition(layout,...own,slot)[1],layout.height - 1);
  for (let y=0;y<layout.height;y++) for (let x=0;x<layout.width;x++) {
   const p=boardPosition(layout,x,y,slot);
   assert.deepEqual(boardPosition(layout,...p,slot),[x,y]);
  }
 }
});
