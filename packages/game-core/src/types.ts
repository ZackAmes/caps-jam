export interface ChainCap {
  id: number;
  owner: string;
  playerSlot: number;
  capType: number;
  setId: number;
  x: number | null;
  y: number | null;
  health: number;
  shield: number;
  stunnedTurns: number;
  availableTurn: number;
  dead: boolean;
}

export interface ChainGame {
  id: number;
  player1: string;
  player2: string;
  layout: number;
  setId: number;
  turnCount: number;
  over: boolean;
  winner: string;
  winnerSlot: number;
  p1Energy: number;
  p2Energy: number;
  energy: number;
  effectIds: number[];
  caps: ChainCap[];
}

/** A player's hand: deterministic cycle through their roster. */
export interface ChainHand {
  gameId: number;
  playerSlot: number;
  roster: number[];
  handSize: number;
  /** Cap ids currently visible in the window (server-computed). */
  window: number[];
}

/** Piece definition fetched from the game's set contract. */
export interface CapTypeDef {
  id: number;
  name: string;
  description: string;
  maxHealth: number;
  attack: number;
  moveRange: number;
  attackRange: number;
  playCost: number;
  moveCost: number;
  abilityCost: number;
  abilityDescription: string;
  abilityTarget: number; // TargetType enum index
  abilityRange: number;
  passives: Passive[];
}

export type TurnAction =
  | { capId: number; kind: 'Play' | 'Move' | 'Ability'; x: number; y: number }
  | { capId: number; kind: 'StackAbility'; targetId: number };
export type PieceSnapshot = Pick<ChainCap, 'id' | 'playerSlot' | 'capType' | 'x' | 'y' | 'health' | 'shield' | 'stunnedTurns' | 'availableTurn' | 'dead'>;
export interface TurnRecord {
  gameId: number; turn: number; playerSlot: number; actions: TurnAction[];
  before: PieceSnapshot[]; after: PieceSnapshot[];
  stackBefore: StackEntry[]; stackAfter: StackEntry[]; resolved: StackEntry[];
  energyBefore: number; energyAfter: number;
}


export type PassiveKind = 'AttackBonus' | 'DamageReduction' | 'AbilityRangeBonus' | 'EnergyGeneration' | 'Regeneration';
export type Relation = 'Ally' | 'Enemy' | 'Any';
export type PassiveCondition =
  | { kind: 'AlliesOnBoard' | 'AllyWithin' | 'EnemyWithin' | 'HealthBelowPercent'; value: number }
  | { kind: 'OnEnemyHalf' }
  | { kind: 'PieceInRow' | 'PieceInColumn'; relation: Relation };
export type PassiveTarget = { kind: 'SelfCap' } | { kind: 'AlliesWithin' | 'EnemiesWithin' | 'AllWithin'; radius: number };
export interface Passive { kind: PassiveKind; amount: number; target: PassiveTarget; conditions: PassiveCondition[] }

export type ImpactKind = 'Damage' | 'Heal' | 'Shield';
export type ImpactSelection =
  | { kind: 'Piece'; id: number }
  | { kind: 'Row'; index: number }
  | { kind: 'Column'; index: number }
  | { kind: 'Within'; x: number; y: number; radius: number };
export interface DelayedImpact { kind: ImpactKind; selection: ImpactSelection; relation: Relation; amount: number }
export interface StackEntry { id: number; sourceId: number; playerSlot: number; announcedTurn: number; readyTurn: number; impact: DelayedImpact }
export interface AbilityStack { gameId: number; nextId: number; entries: StackEntry[] }
