import { CallData, type Account, type RpcProvider } from 'starknet';
import { decodeGame, decodeHand, decodeCapType } from '@caps/game-core/decode';
import { encodeActions } from '@caps/game-core/encode';
import { getLayout, type LayoutConfig } from '@caps/game-core/board';
import type { ChainGame, ChainHand, CapTypeDef, TurnAction } from '@caps/game-core/types';
import type { GameAdapter, GameInfo } from '../ports';

export interface PositionV2 {
  game: ChainGame;
  hand: ChainHand;
  definitions: Map<number, CapTypeDef>;
  layout: LayoutConfig;
}

/** All ABI and rules-version assumptions live here, outside the polling worker. */
export class CapsV2Adapter implements GameAdapter<ChainGame, PositionV2, TurnAction> {
  private definitions = new Map<string, CapTypeDef>();
  constructor(private provider: RpcProvider, private account: Account, private actionsAddress: string) {}

  private call(entrypoint: string, calldata: (string | number)[] = []) {
    return this.provider.callContract({ contractAddress: this.actionsAddress, entrypoint, calldata: CallData.compile(calldata) });
  }

  async checkCompatibility() {
    const [version] = await this.call('rules_version');
    if (Number(version) !== 2) throw new Error(`Unsupported CAPS rules version ${Number(version)}; add an adapter before running this bot.`);
    await this.gameCount(); // The deployment must also expose the discovery endpoint.
  }

  async gameCount() { return Number((await this.call('get_game_count'))[0]); }

  async readGame(id: number): Promise<GameInfo<ChainGame> | null> {
    const game = decodeGame(await this.call('get_game', [id]));
    return game ? { id: game.id, turn: game.turnCount, over: game.over, players: [game.player1, game.player2], state: game } : null;
  }

  async prepare(info: GameInfo<ChainGame>): Promise<PositionV2> {
    const game = info.state;
    if (game.setId !== 0) throw new Error(`Reference strategy does not support set ${game.setId}`);
    if (![0, 1, 2, 3].includes(game.layout)) throw new Error(`Unsupported layout ${game.layout}`);
    const hand = decodeHand(await this.call('get_hand', [game.id, game.turnCount % 2]));
    if (!hand) throw new Error('Missing hand');
    const definitions = new Map<number, CapTypeDef>();
    for (const type of new Set(game.caps.map(c => c.capType))) {
      const key = `${game.setId}:${type}`;
      let def = this.definitions.get(key);
      if (!def) {
        def = decodeCapType(await this.call('get_cap_data', [game.id, type])) ?? undefined;
        if (!def) throw new Error(`Missing definition for piece ${type}`);
        this.definitions.set(key, def);
      }
      definitions.set(type, def);
    }
    return { game, hand, definitions, layout: getLayout(game.layout) };
  }

  async sendTurn(game: GameInfo<ChainGame>, actions: TurnAction[]): Promise<string> {
    const response = await this.account.execute({
      contractAddress: this.actionsAddress,
      entrypoint: 'take_turn_if_current',
      calldata: CallData.compile([game.id, game.turn, ...encodeActions(actions)]),
    }, { tip: 0 });
    return response.transaction_hash;
  }

  async transactionStatus(hash: string): Promise<'pending' | 'succeeded' | 'reverted'> {
    try {
      const receipt = await this.provider.getTransactionReceipt(hash);
      if (receipt.isReverted()) return 'reverted';
      if (receipt.isSuccess() && ['ACCEPTED_ON_L2', 'ACCEPTED_ON_L1'].includes(receipt.finality_status)) return 'succeeded';
      return 'pending';
    } catch (error) {
      // A just-broadcast hash may not have propagated; other RPC failures must surface.
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 29) return 'pending';
      throw error;
    }
  }
}
