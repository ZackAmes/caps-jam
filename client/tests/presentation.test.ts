import { test, expect } from 'bun:test';
import { viewerSlot, pathEdges, effectTiming } from '../src/lib/game/presentation';
import { getLayout } from '@caps/game-core/board';
import type { ChainGame, AbilityStack, StackEntry } from '@caps/game-core/types';

test('viewer remains P1 during the bot turn; solo follows the active side', () => {
    const game = { player1: '0x01', player2: '0x02', turnCount: 1 } as ChainGame;
    expect(viewerSlot(game, '0x1')).toBe(0);
    expect(viewerSlot(game, '0x2')).toBe(1);
    expect(viewerSlot(game, '0x3')).toBeNull();
    expect(viewerSlot({...game, player2: '0x1'}, '0x01')).toBe(1);
});
test('path overlay draws each legal edge once and excludes corner shortcuts', () => {
    for (const id of [0, 1, 2, 3]) {
        const layout = getLayout(id), edges = pathEdges(layout);
        for (let y = 0; y < 5; y++) for (let x = 0; x < 5; x++) {
            for (const [nx, ny] of layout.neighbors([x, y])) {
                expect(edges.filter(e => e.x1 === x && e.y1 === y && e.x2 === nx && e.y2 === ny || e.x2 === x && e.y2 === y && e.x1 === nx && e.y1 === ny)).toHaveLength(1);
            }
        }
        expect(edges.some(e => e.x1 === 1 && e.y1 === 0 && e.x2 === 0 && e.y2 === 1)).toBe(false);
    }
});
test('effect timing describes the response turn and blocked ready effects', () => {
    const first = { id: 1, readyTurn: 2 } as StackEntry;
    const second = { id: 2, readyTurn: 3 } as StackEntry;
    const stack: AbilityStack = { gameId: 1, nextId: 2, entries: [first, second] };
    expect(effectTiming(first, {...stack, entries: [first]}, 0, 0)).toBe('Ready after your opponent’s next turn');
    expect(effectTiming(first, stack, 1, 1)).toBe('Ready · waiting for newer effects above it');
    expect(effectTiming(second, stack, 2, 0)).toBe('Resolves when this turn ends');
});
