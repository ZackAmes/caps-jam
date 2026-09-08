import { test, expect } from 'bun:test';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { FileStore } from '../src/store';

test('checkpoint survives restart, rejects another deployment, and excludes a second worker', () => {
  const dir = mkdtempSync(join(tmpdir(), 'caps-bot-test-'));
  try {
    const store = new FileStore(join(dir, 'checkpoint.json'));
    const state = store.load('deployment-a');
    state.scannedThrough = 91; state.active = [80]; state.pending = { gameId: 80, turn: 3, hash: '0xabc' };
    store.save(state);
    expect(new FileStore(join(dir, 'checkpoint.json')).load('deployment-a')).toEqual(state);
    expect(() => store.load('deployment-b')).toThrow('different chain');
    const unlock = store.lock();
    expect(() => store.lock()).toThrow('Another bot worker');
    unlock(); store.lock()();
  } finally { rmSync(dir, { recursive: true, force: true }); }
});
