import { closeSync, mkdirSync, openSync, readFileSync, renameSync, unlinkSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import type { Checkpoint, CheckpointStore } from './ports';

export class FileStore implements CheckpointStore {
  constructor(private path: string) { mkdirSync(dirname(path), { recursive: true, mode: 0o700 }); }

  load(identity: string): Checkpoint {
    try {
      const state: Checkpoint = JSON.parse(readFileSync(this.path, 'utf8'));
      if (state.identity !== identity) throw new Error('Checkpoint belongs to a different chain, deployment, or bot account. Choose a new BOT_STATE_PATH.');
      if (!Number.isSafeInteger(state.scannedThrough) || state.scannedThrough < 0 || !Array.isArray(state.active)
          || state.active.some(id => !Number.isSafeInteger(id) || id < 1) || !Number.isSafeInteger(state.nextActive) || state.nextActive < 0
          || (state.pending && (!Number.isSafeInteger(state.pending.gameId) || state.pending.gameId < 1
          || !Number.isSafeInteger(state.pending.turn) || state.pending.turn < 0 || !/^0x[0-9a-f]+$/i.test(state.pending.hash)))) throw new Error('Invalid checkpoint');
      return state;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error;
      return { identity, scannedThrough: 0, active: [], nextActive: 0 };
    }
  }

  save(state: Checkpoint): void {
    const temporary = `${this.path}.${process.pid}.tmp`;
    writeFileSync(temporary, JSON.stringify(state, null, 2) + '\n', { mode: 0o600 });
    renameSync(temporary, this.path);
  }

  lock(): () => void {
    const path = `${this.path}.lock`;
    try { closeSync(openSync(path, 'wx', 0o600)); }
    catch (error) {
      if ((error as NodeJS.ErrnoException).code !== 'EEXIST') throw error;
      const pid = Number(readFileSync(path, 'utf8'));
      if (!Number.isInteger(pid) || pid <= 0) throw new Error('Invalid worker lock; inspect it before removing it');
      try { process.kill(pid, 0); }
      catch (probe) {
        if ((probe as NodeJS.ErrnoException).code !== 'ESRCH') throw probe;
        unlinkSync(path);
        return this.lock();
      }
      throw new Error(`Another bot worker is running (PID ${pid})`);
    }
    writeFileSync(path, String(process.pid), { mode: 0o600 });
    return () => { try { unlinkSync(path); } catch { /* already released */ } };
  }
}
