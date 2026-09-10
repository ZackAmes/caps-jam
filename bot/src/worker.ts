import { sameAddress, type Checkpoint, type CheckpointStore, type GameAdapter, type Logger, type Strategy } from './ports';

export class BotWorker<State, Position, Action> {
  constructor(
    private adapter: GameAdapter<State, Position, Action>,
    private strategy: Strategy<Position, Action>,
    private address: string,
    private state: Checkpoint,
    private store: CheckpointStore,
    private log: Logger,
    private batchSize = 20,
  ) {}

  /** One serialized poll. At most one transaction may be in flight across all games. */
  async tick(): Promise<void> {
    const count = await this.adapter.gameCount();
    const end = Math.min(count, this.state.scannedThrough + this.batchSize);
    for (let id = this.state.scannedThrough + 1; id <= end; id++) {
      try {
        const game = await this.adapter.readGame(id);
        if (game && !game.over && game.players.some(p => sameAddress(p, this.address))) {
          if (!this.state.active.includes(id)) this.state.active.push(id);
          this.log('game_discovered', { gameId: id });
        }
        this.state.scannedThrough = id;
        this.store.save(this.state);
      } catch (error) {
        this.log('discovery_retry', { gameId: id, error: message(error) });
        break; // Never advance past a failed read and silently miss a challenge.
      }
    }

    if (this.state.pending) {
      const status = await this.adapter.transactionStatus(this.state.pending.hash);
      if (status === 'pending') return;
      this.log(`transaction_${status}`, { ...this.state.pending });
      delete this.state.pending;
      this.store.save(this.state);
    }

    const active = [...this.state.active];
    for (let i = 0; i < Math.min(active.length, this.batchSize); i++) {
      const index = (this.state.nextActive + i) % active.length;
      const id = active[index];
      let sending = false;
      try {
        const game = await this.adapter.readGame(id);
        if (!game || game.over || !game.players.some(p => sameAddress(p, this.address))) {
          this.state.active = this.state.active.filter(g => g !== id);
          this.store.save(this.state);
          continue;
        }
        const ownTurn = sameAddress(game.players[game.turn % 2], this.address);
        let hash: string | null, actionCount = 0;
        if (!ownTurn) {
          if (!this.adapter.claimTimeout) continue;
          sending = true;
          hash = await this.adapter.claimTimeout(game);
          if (!hash) { sending = false; continue; }
        } else {
          const position = await this.adapter.prepare(game);
          const actions = this.strategy.chooseTurn(position);
          actionCount = actions.length;
          sending = true;
          hash = await this.adapter.sendTurn(game, actions);
        }
        this.state.pending = { gameId: id, turn: game.turn, hash };
        this.state.nextActive = (index + 1) % active.length;
        this.store.save(this.state);
        this.log(ownTurn ? 'turn_submitted' : 'timeout_claim_submitted', { gameId: id, turn: game.turn, actionCount, hash });
        return;
      } catch (error) {
        this.log('game_retry', { gameId: id, error: message(error) });
        if (sending) return; // Do not submit another nonce after an ambiguous broadcast failure.
      }
    }
    this.state.nextActive = active.length ? (this.state.nextActive + this.batchSize) % active.length : 0;
    this.store.save(this.state);
  }
}

export function message(error: unknown): string {
  if (typeof error === 'object' && error && 'baseError' in error) {
    const rpc = error.baseError as { code?: number; message?: string; data?: unknown };
    return `RPC ${rpc.code}: ${rpc.message ?? 'Request failed'} ${rpc.data ? JSON.stringify(rpc.data).slice(0, 500) : ''}`;
  }
  return (error instanceof Error ? error.message : String(error)).replace(/https?:\/\/[^\s"']+/g, '[rpc]').slice(0, 800);
}
