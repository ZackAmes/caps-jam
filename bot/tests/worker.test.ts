import { test, expect } from 'bun:test';
import { BotWorker } from '../src/worker';
import type { Checkpoint, GameAdapter, GameInfo } from '../src/ports';

function fixture(count = 1) {
  const state: Checkpoint = { identity: 'test', scannedThrough: 0, active: [], nextActive: 0 };
  const games = new Map<number, GameInfo<null>>();
  for (let id = 1; id <= count; id++) games.set(id, { id, turn: 1, over: false, players: ['0x1','0x2'], state: null });
  const sent: number[] = [];
  let status: 'pending' | 'succeeded' | 'reverted' = 'pending';
  let failedRead = 0;
  let broadcastFailure = false;
  const adapter: GameAdapter<null, null, string> = {
    gameCount: async () => count,
    readGame: async id => { if (id === failedRead) throw new Error('RPC unavailable'); return games.get(id) ?? null; },
    prepare: async () => null,
    sendTurn: async game => { sent.push(game.id); if (broadcastFailure) throw new Error('Timeout'); return `0x${game.id}`; },
    transactionStatus: async () => status,
  };
  let saved: Checkpoint | undefined;
  const store = { save: (s: Checkpoint) => { saved = structuredClone(s); } };
  const strategy = { name: 'test', chooseTurn: () => ['move'] };
  const makeWorker = (checkpoint = state) => new BotWorker(adapter, strategy, '0x02', checkpoint, store, () => {});
  return { state, games, sent, makeWorker, saved: () => saved!, status: (s: typeof status) => status = s, failRead: (id: number) => failedRead = id, failBroadcast: () => broadcastFailure = true };
}

test('discovers beyond forty games without skipping failed reads', async () => {
  const f = fixture(65);
  for (const [id, game] of f.games) if (id !== 65) game.players = ['0x3','0x4'];
  const worker = f.makeWorker();
  f.failRead(8); await worker.tick(); expect(f.state.scannedThrough).toBe(7);
  f.failRead(0);
  for (let i = 0; i < 3; i++) await worker.tick();
  expect(f.state.scannedThrough).toBe(65); expect(f.sent).toEqual([65]);
});

test('restart waits for pending transaction then uses a fresh turn and rotates games', async () => {
  const f = fixture(2); await f.makeWorker().tick();
  expect(f.sent).toEqual([1]);
  const restarted = f.makeWorker(f.saved()); await restarted.tick();
  expect(f.sent).toEqual([1]);
  f.games.get(1)!.turn = 2; f.status('succeeded'); await restarted.tick();
  expect(f.sent).toEqual([1,2]);
});

test('does not act on opponent turns and retires finished games', async () => {
  const f = fixture(2); f.games.get(1)!.turn = 0;
  f.state.active = [2]; f.games.get(2)!.over = true;
  await f.makeWorker().tick();
  expect(f.sent).toEqual([]); expect(f.state.active).toEqual([1]);
});

test('ambiguous broadcast stops other sends in the same poll', async () => {
  const f = fixture(2); f.failBroadcast(); await f.makeWorker().tick();
  expect(f.sent).toEqual([1]);
});

test('reverted transaction is retried from freshly read state', async () => {
  const f = fixture(); const worker = f.makeWorker(); await worker.tick();
  f.status('reverted'); f.games.get(1)!.turn = 2; await worker.tick();
  expect(f.sent).toEqual([1]); expect(f.state.pending).toBeUndefined();
});
