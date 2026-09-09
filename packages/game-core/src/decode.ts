import type { ChainGame, ChainHand, CapTypeDef, Passive, PassiveKind, PassiveCondition, Relation, AbilityStack, StackEntry, ImpactKind, ImpactSelection, TurnRecord, TurnAction, PieceSnapshot } from './types';
const num = (s: string): number => Number(BigInt(s));

export function decodeHand(f: string[]): ChainHand | null {
  if (!f || f.length === 0) return null;

  let i = 0;
  const option = num(f[i++]);
  if (option !== 0) return null;

  const hand: ChainHand = {
    gameId: num(f[i++]),
    playerSlot: num(f[i++]),
    roster: [],
    handSize: 0,
    window: [],
  };
  // roster: Array<u64>
  const rosterLen = num(f[i++]);
  for (let k = 0; k < rosterLen; k++) hand.roster.push(num(f[i++]));
  hand.handSize = num(f[i++]);
  // window: Span<u64>
  const windowLen = num(f[i++]);
  for (let k = 0; k < windowLen; k++) hand.window.push(num(f[i++]));
  return hand;
}

export function decodeCapType(f: string[]): CapTypeDef | null {
  if (!f || f.length === 0) return null;

  let i = 0;
  const option = num(f[i++]);
  if (option !== 0) return null;

  const id = num(f[i++]);
  const readText = () => {
    const count = num(f[i++]);
    const bytes: number[] = [];
    const append = (word: string, length: number) => {
      const hex = BigInt(word).toString(16).padStart(length * 2, '0');
      for (let k = 0; k < length; k++) bytes.push(parseInt(hex.slice(k * 2, k * 2 + 2), 16));
    };
    for (let k = 0; k < count; k++) append(f[i++], 31);
    const pending = f[i++];
    const pendingLength = num(f[i++]);
    append(pending, pendingLength);
    return new TextDecoder().decode(new Uint8Array(bytes));
  };
  const name = readText();
  const desc = readText();
  const maxHealth = num(f[i++]);
  const attack = num(f[i++]);
  const moveRange = num(f[i++]);
  const attackRange = num(f[i++]);
  const playCost = num(f[i++]);
  const moveCost = num(f[i++]);
  const abilityCost = num(f[i++]);
  const abilityDescription = readText();
  const abilityTarget = num(f[i++]);
  const abilityRange = num(f[i++]);
  const passives: Passive[] = [];
  const kinds: PassiveKind[] = ['AttackBonus', 'DamageReduction', 'AbilityRangeBonus', 'EnergyGeneration', 'Regeneration'];
  const relations: Relation[] = ['Ally', 'Enemy', 'Any'];
  const count = num(f[i++]);
  for (let p = 0; p < count; p++) {
    const kind = kinds[num(f[i++])];
    if (!kind) throw new Error('Unknown passive kind');
    const amount = num(f[i++]);
    const targetIndex = num(f[i++]);
    const targetKinds = ['SelfCap', 'AlliesWithin', 'EnemiesWithin', 'AllWithin'] as const;
    const targetKind = targetKinds[targetIndex];
    if (!targetKind) throw new Error('Unknown passive target');
    const target = targetKind === 'SelfCap' ? { kind: targetKind } : { kind: targetKind, radius: num(f[i++]) };
    const conditions: PassiveCondition[] = [];
    const length = num(f[i++]);
    for (let c = 0; c < length; c++) {
      const variant = num(f[i++]);
      if (variant < 4) {
        const kind = (['AlliesOnBoard', 'AllyWithin', 'EnemyWithin', 'HealthBelowPercent'] as const)[variant];
        conditions.push({ kind, value: num(f[i++]) });
      } else if (variant === 4) conditions.push({ kind: 'OnEnemyHalf' });
      else if (variant === 5 || variant === 6) {
        const relation = relations[num(f[i++])];
        if (!relation) throw new Error('Unknown passive relation');
        conditions.push({ kind: variant === 5 ? 'PieceInRow' : 'PieceInColumn', relation });
      } else throw new Error('Unknown passive condition');
    }
    passives.push({ kind, amount, target, conditions });
  }

  return {
    id,
    name,
    description: desc,
    maxHealth,
    attack,
    moveRange,
    attackRange,
    playCost,
    moveCost,
    abilityCost,
    abilityDescription,
    abilityTarget,
    abilityRange,
    passives,
  };
}

export function decodeGame(f: string[]): ChainGame | null {
  if (!f || f.length === 0) return null;

  let i = 0;
  const option = num(f[i++]);
  if (option !== 0) return null;

  const game: ChainGame = {
    id: num(f[i++]),
    player1: f[i++],
    player2: f[i++],
    layout: num(f[i++]),
    setId: num(f[i++]),
    turnCount: num(f[i++]),
    over: num(f[i++]) === 1,
    winner: f[i++],
    winnerSlot: num(f[i++]),
    p1Energy: 0,
    p2Energy: 0,
    energy: 0,
    effectIds: [],
    caps: [],
  };

  // caps_ids: Array<u64>
  const idCount = num(f[i++]);
  for (let k = 0; k < idCount; k++) i++;
  // effect_ids: Array<u64>
  const effectCount = num(f[i++]);
  for (let k = 0; k < effectCount; k++) {
    game.effectIds.push(num(f[i++]));
  }
  // energy: u8, last_action_timestamp: u64
  game.energy = num(f[i++]);
  game.p1Energy = num(f[i++]);
  game.p2Energy = num(f[i++]);
  i++; // next effect id
  i++; // timestamp

  const capCount = num(f[i++]);
  for (let k = 0; k < capCount; k++) {
    const id = num(f[i++]);
    const owner = f[i++];
    const playerSlot = num(f[i++]);
    const capType = num(f[i++]);
    const setId = num(f[i++]);
    const locVariant = num(f[i++]);
    let x: number | null = null;
    let y: number | null = null;
    if (locVariant === 1) {
      x = num(f[i++]);
      y = num(f[i++]);
    }
    const health = num(f[i++]);
    const shield = num(f[i++]);
    const stunnedTurns = num(f[i++]);
    const availableTurn = num(f[i++]);
    game.caps.push({
      id, owner, playerSlot, capType, setId, x, y, health, shield, stunnedTurns, availableTurn, dead: locVariant === 2,
    });
  }

  return game;
}



export function decodeStack(f: string[]): AbilityStack {
  let i = 0;
  const read = () => {
    if (i >= f.length) throw new Error('Truncated ability stack');
    return num(f[i++]);
  };
  const gameId = read(), nextId = read(), entries = readStackEntries(read);
  if (i !== f.length) throw new Error('Unexpected ability stack fields');
  return { gameId, nextId, entries };
}
function readStackEntries(read: () => number): StackEntry[] {
  const count = read();
  if (count > 32) throw new Error('Invalid ability stack size');
  const entries: StackEntry[] = [];
  for (let n = 0; n < count; n++) {
    const id = read(), sourceId = read(), playerSlot = read(), announcedTurn = read(), readyTurn = read();
    const kind = (['Damage', 'Heal', 'Shield'] as ImpactKind[])[read()];
    const variant = read();
    let selection: ImpactSelection;
    if (variant === 0) selection = { kind: 'Piece', id: read() };
    else if (variant === 1 || variant === 2) selection = { kind: variant === 1 ? 'Row' : 'Column', index: read() };
    else if (variant === 3) selection = { kind: 'Within', x: read(), y: read(), radius: read() };
    else throw new Error('Unknown delayed selection');
    const relation = (['Ally', 'Enemy', 'Any'] as Relation[])[read()];
    const amount = read();
    if (!kind || !relation || playerSlot > 1) throw new Error('Invalid delayed impact');
    entries.push({ id, sourceId, playerSlot, announcedTurn, readyTurn, impact: {kind,selection,relation,amount} });
  }
  return entries;
}

export function decodeTurnRecord(f: string[]): TurnRecord | null {
  let i = 0;
  const read = () => { if (i >= f.length) throw new Error('Truncated turn record'); return num(f[i++]); };
  if (read() !== 0) return null;
  const gameId = read(), turn = read(), recorded = read(), playerSlot = read();
  if (recorded !== 1 || playerSlot > 1) throw new Error('Invalid turn record');
  const actions: TurnAction[] = [];
  const count = read(); if (count > 32) throw new Error('Invalid action count');
  for (let k = 0; k < count; k++) {
    const capId = read(), variant = read();
    if (variant === 3) actions.push({capId, kind:'StackAbility', targetId:read()});
    else { const kind = (['Play','Move','Ability'] as const)[variant]; if (!kind) throw new Error('Unknown action'); actions.push({capId,kind,x:read(),y:read()}); }
  }
  const pieces = (): PieceSnapshot[] => {
    const n = read(); if (n > 256) throw new Error('Invalid piece count');
    return Array.from({length:n}, () => {
      const id = read(), playerSlot = read(), capType = read(), location = read();
      if (location > 2) throw new Error('Invalid location');
      const x = location === 1 ? read() : null, y = location === 1 ? read() : null;
      return {id,playerSlot,capType,x,y,dead:location===2,health:read(),shield:read(),stunnedTurns:read(),availableTurn:read()};
    });
  };
  const before = pieces(), after = pieces();
  const stackBefore = readStackEntries(read), stackAfter = readStackEntries(read), resolved = readStackEntries(read);
  const energyBefore = read(), energyAfter = read();
  if (i !== f.length) throw new Error('Unexpected turn record fields');
  return {gameId,turn,playerSlot,actions,before,after,stackBefore,stackAfter,resolved,energyBefore,energyAfter};
}
