/** The worker knows whose turn it is, but nothing about CAPS board rules. */
export interface GameInfo<State> {
  id: number;
  turn: number;
  over: boolean;
  players: [string, string];
  state: State;
}

export interface GameAdapter<State, Position, Action> {
  claimTimeout?(game: GameInfo<State>): Promise<string | null>;
  gameCount(): Promise<number>;
  readGame(id: number): Promise<GameInfo<State> | null>;
  prepare(game: GameInfo<State>): Promise<Position>;
  sendTurn(game: GameInfo<State>, actions: Action[]): Promise<string>;
  transactionStatus(hash: string): Promise<'pending' | 'succeeded' | 'reverted'>;
}

export interface Strategy<Position, Action> {
  name: string;
  chooseTurn(position: Position): Action[];
}

export interface Checkpoint {
  identity: string;
  scannedThrough: number;
  active: number[];
  nextActive: number;
  pending?: { gameId: number; turn: number; hash: string };
}

export interface CheckpointStore {
  save(state: Checkpoint): void;
}

export type Logger = (event: string, fields?: Record<string, unknown>) => void;
export const sameAddress = (a: string, b: string) => BigInt(a) === BigInt(b);
