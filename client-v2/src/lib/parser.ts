// WASM Cairo Type Deserialization Helpers

import { type BigNumberish, type ByteArray, cairo } from "starknet";

export interface Vec2 {
  x: number;
  y: number;
}

export interface CapType {
  id: number;
  name: string;
  description: string;
  play_cost: number;
  move_cost: number;
  attack_cost: number;
  attack_range: Vec2[];
  ability_range: Vec2[];
  ability_description: string;
  move_range: Vec2;
  attack_dmg: number;
  base_health: number;
  ability_target: string;
  ability_cost: number;
}

// Location enum
export type Location = 
  | { type: 'Bench'; value: string }
  | { type: 'Board'; value: Vec2 }
  | { type: 'Hidden'; value: number }
  | { type: 'Dead'; value: string };

export interface Cap {
  id: number;
  owner: number;
  location: Location;
  set_id: number;
  cap_type: number;
  dmg_taken: number;
  shield_amt: number;
}

// EffectTarget enum
export type EffectTarget = 
  | { type: 'Cap'; value: number }
  | { type: 'Square'; value: Vec2 };

export interface Effect {
  game_id: number;
  effect_id: number;
  effect_type: string;
  target: EffectTarget;
  remaining_triggers: number;
}

export interface Game {
  id: number;
  player1: string;
  player2: string;
  caps_ids: number[];
  turn_count: number;
  over: boolean;
  effect_ids: number[];
  last_action_timestamp: number;
}

export interface GameState {
  game: Game;
  effects: Effect[];
  caps: Cap[];
}

// Helper to parse ByteArray from felts using the custom stringFromByteArray helper
function parseByteArray(felts: string[], idx: number): { value: string; nextIdx: number } {
  const startIdx = idx;
  const dataLength = Number(felts[idx++]);
  
  const words: BigNumberish[] = [];
  for (let i = 0; i < dataLength; i++) {
    words.push(felts[idx++]);
  }
  const pendingWord = felts[idx++];
  const pendingWordLen = Number(felts[idx++]);
  
  console.log(`[parseByteArray] idx=${startIdx}, dataLen=${dataLength}, pendingLen=${pendingWordLen}, nextIdx=${idx}`);
  
  try {
    // Construct a ByteArray object and decode it
    const byteArray: ByteArray = {
      data: words,
      pending_word: pendingWord,
      pending_word_len: pendingWordLen
    };
    const result = stringFromByteArray(byteArray);
    console.log(`[parseByteArray] Decoded: "${result}"`);
    
    return { value: result, nextIdx: idx };
  } catch (error) {
    console.error(`[parseByteArray] Error:`, error);
    throw error;
  }
}

// Helper to parse Vec2
function parseVec2(felts: string[], idx: number): { value: Vec2; nextIdx: number } {
  return {
    value: { x: Number(felts[idx]), y: Number(felts[idx + 1]) },
    nextIdx: idx + 2
  };
}

// Helper to parse Array of Vec2
function parseVec2Array(felts: string[], idx: number): { value: Vec2[]; nextIdx: number } {
  const startIdx = idx;
  const len = Number(felts[idx++]);
  console.log(`[parseVec2Array] idx: ${startIdx}, arrayLength: ${len}`);
  
  if (isNaN(len) || !isFinite(len)) {
    console.error(`[parseVec2Array] Invalid length value: ${len}, felt was: "${felts[startIdx]}"`);
    throw new RangeError(`Invalid array length: ${len}`);
  }
  
  const arr: Vec2[] = [];
  for (let i = 0; i < len; i++) {
    const parsed = parseVec2(felts, idx);
    arr.push(parsed.value);
    idx = parsed.nextIdx;
  }
  console.log(`[parseVec2Array] Parsed ${len} Vec2s, nextIdx: ${idx}`);
  return { value: arr, nextIdx: idx };
}

// Enum names
const TargetTypeNames = ['None', 'SelfCap', 'TeamCap', 'OpponentCap', 'AnyCap', 'AnySquare'];
const LocationNames = ['Bench', 'Board', 'Hidden', 'Dead'];
const EffectTypeNames = ['DamageBuff', 'Shield', 'Heal', 'DOT', 'MoveBonus', 'AttackBonus', 'BonusRange', 'MoveDiscount', 'AttackDiscount', 'AbilityDiscount', 'ExtraEnergy', 'Stun', 'Double'];
const EffectTargetNames = ['Cap', 'Square'];

// Parse CapType from serialized output
export function parseCapType(rawOutput: string): CapType | null {
  console.log(`[parseCapType] Raw output: ${rawOutput}`);
  
  // Process arrays: [] becomes "0", [a b c] becomes "3 a b c"
  // Arrays include their length at the start, so we need to add the count
  let normalized = rawOutput.replace(/\[([^\]]*)\]/g, (match, contents) => {
    const elements = contents.trim();
    if (elements === '') {
      return '0';  // Empty array
    }
    const items = elements.split(/\s+/).filter((s: string) => s.length > 0);
    return `${items.length} ${elements}`;
  });
  
  const felts = normalized.split(/\s+/).filter((s: string) => s.length > 0);
  
  console.log(`[parseCapType] Normalized felts (${felts.length}):`, felts);
  
  let idx = 0;
  
  // Parse CapType struct - first element is the ID
  const id = Number(felts[idx++]);
  console.log(`[parseCapType] ID: ${id}, idx: ${idx}`);
  
  const name = parseByteArray(felts, idx);
  idx = name.nextIdx;
  
  const description = parseByteArray(felts, idx);
  idx = description.nextIdx;
  
  const play_cost = Number(felts[idx++]);
  const move_cost = Number(felts[idx++]);
  const attack_cost = Number(felts[idx++]);
  
  const attack_range = parseVec2Array(felts, idx);
  idx = attack_range.nextIdx;
  
  const ability_range = parseVec2Array(felts, idx);
  idx = ability_range.nextIdx;
  
  const ability_description = parseByteArray(felts, idx);
  idx = ability_description.nextIdx;
  
  const move_range = parseVec2(felts, idx);
  idx = move_range.nextIdx;
  
  const attack_dmg = Number(felts[idx++]);
  const base_health = Number(felts[idx++]);
  
  const ability_target = TargetTypeNames[Number(felts[idx++])];
  const ability_cost = Number(felts[idx++]);
  
  return {
    id,
    name: name.value,
    description: description.value,
    play_cost,
    move_cost,
    attack_cost,
    attack_range: attack_range.value,
    ability_range: ability_range.value,
    ability_description: ability_description.value,
    move_range: move_range.value,
    attack_dmg,
    base_health,
    ability_target,
    ability_cost
  };
}


export function stringFromByteArray(myByteArray: ByteArray): string {
    const pending_word: string =
      BigInt(myByteArray.pending_word) === 0n
        ? ''
        : decodeShortString(toHex(myByteArray.pending_word));
    return (
      myByteArray.data.reduce<string>((cumuledString, encodedString: BigNumberish) => {
        const add: string =
          BigInt(encodedString) === 0n ? '' : decodeShortString(toHex(encodedString));
        return cumuledString + add;
      }, '') + pending_word
    );
  }

  export function toHex(value: BigNumberish): string {
    return addHexPrefix(toBigInt(value).toString(16));
  }

  export function toBigInt(value: BigNumberish): bigint {
    return BigInt(value);
  }

  export function addHexPrefix(hex: string): string {
    return `0x${removeHexPrefix(hex)}`;
  }

  export function removeHexPrefix(hex: string): string {
    return hex.startsWith('0x') || hex.startsWith('0X') ? hex.slice(2) : hex;
  }

  export function decodeShortString(str: string): string {
    if (!isASCII(str)) throw new Error(`${str} is not an ASCII string`);
    if (isHex(str)) {
      return removeHexPrefix(str).replace(/.{2}/g, (hex) => String.fromCharCode(parseInt(hex, 16)));
    }
    if (isDecimalString(str)) {
      return decodeShortString('0X'.concat(BigInt(str).toString(16)));
    }
    throw new Error(`${str} is not Hex or decimal`);
  }

  export function isASCII(str: string): boolean {
    // eslint-disable-next-line no-control-regex
    return /^[\x00-\x7F]*$/.test(str);
  }
  export function isHex(hex: string): boolean {
    return /^0[xX][0-9a-fA-F]*$/.test(hex);
  }
  export function isDecimalString(str: string): boolean {
    return /^[0-9]*$/i.test(str);
  }

// Helper to parse ContractAddress (felt252)
function parseContractAddress(felts: string[], idx: number): { value: string; nextIdx: number } {
  return { value: felts[idx], nextIdx: idx + 1 };
}

// Helper to parse number array
function parseNumberArray(felts: string[], idx: number): { value: number[]; nextIdx: number } {
  const startIdx = idx;
  const len = Number(felts[idx++]);
  console.log(`[parseNumberArray] idx: ${startIdx}, arrayLength: ${len}`);
  
  if (isNaN(len) || !isFinite(len)) {
    console.error(`[parseNumberArray] Invalid length value: ${len}`);
    throw new RangeError(`Invalid array length: ${len}`);
  }
  
  const arr: number[] = [];
  for (let i = 0; i < len; i++) {
    arr.push(Number(felts[idx++]));
  }
  console.log(`[parseNumberArray] Parsed ${len} numbers, nextIdx: ${idx}`);
  return { value: arr, nextIdx: idx };
}

// Parse Location enum
function parseLocation(felts: string[], idx: number): { value: Location; nextIdx: number } {
  const variantIdx = Number(felts[idx++]);
  const variantName = LocationNames[variantIdx];
  console.log(`[parseLocation] variant: ${variantName} (${variantIdx})`);
  
  switch (variantName) {
    case 'Bench': {
      const addr = parseContractAddress(felts, idx);
      return { value: { type: 'Bench', value: addr.value }, nextIdx: addr.nextIdx };
    }
    case 'Board': {
      const pos = parseVec2(felts, idx);
      return { value: { type: 'Board', value: pos.value }, nextIdx: pos.nextIdx };
    }
    case 'Hidden': {
      const val = Number(felts[idx]);
      return { value: { type: 'Hidden', value: val }, nextIdx: idx + 1 };
    }
    case 'Dead': {
      const addr = parseContractAddress(felts, idx);
      return { value: { type: 'Dead', value: addr.value }, nextIdx: addr.nextIdx };
    }
    default:
      throw new Error(`Unknown Location variant: ${variantName}`);
  }
}

// Parse EffectTarget enum
function parseEffectTarget(felts: string[], idx: number): { value: EffectTarget; nextIdx: number } {
  const variantIdx = Number(felts[idx++]);
  const variantName = EffectTargetNames[variantIdx];
  console.log(`[parseEffectTarget] variant: ${variantName} (${variantIdx})`);
  
  switch (variantName) {
    case 'Cap': {
      const capId = Number(felts[idx]);
      return { value: { type: 'Cap', value: capId }, nextIdx: idx + 1 };
    }
    case 'Square': {
      const pos = parseVec2(felts, idx);
      return { value: { type: 'Square', value: pos.value }, nextIdx: pos.nextIdx };
    }
    default:
      throw new Error(`Unknown EffectTarget variant: ${variantName}`);
  }
}

// Parse Cap struct
function parseCap(felts: string[], idx: number): { value: Cap; nextIdx: number } {
  console.log(`[parseCap] Starting at idx: ${idx}`);
  
  const id = Number(felts[idx++]);
  const owner = Number(felts[idx++]);
  
  const location = parseLocation(felts, idx);
  idx = location.nextIdx;
  
  const set_id = Number(felts[idx++]);
  const cap_type = Number(felts[idx++]);
  const dmg_taken = Number(felts[idx++]);
  const shield_amt = Number(felts[idx++]);
  
  console.log(`[parseCap] Parsed cap id=${id}, nextIdx: ${idx}`);
  
  return {
    value: {
      id,
      owner,
      location: location.value,
      set_id,
      cap_type,
      dmg_taken,
      shield_amt
    },
    nextIdx: idx
  };
}

// Parse Effect struct
function parseEffect(felts: string[], idx: number): { value: Effect; nextIdx: number } {
  console.log(`[parseEffect] Starting at idx: ${idx}`);
  
  const game_id = Number(felts[idx++]);
  const effect_id = Number(felts[idx++]);
  
  const effect_type_idx = Number(felts[idx++]);
  const effect_type = EffectTypeNames[effect_type_idx];
  
  const target = parseEffectTarget(felts, idx);
  idx = target.nextIdx;
  
  const remaining_triggers = Number(felts[idx++]);
  
  console.log(`[parseEffect] Parsed effect id=${effect_id}, type=${effect_type}, nextIdx: ${idx}`);
  
  return {
    value: {
      game_id,
      effect_id,
      effect_type,
      target: target.value,
      remaining_triggers
    },
    nextIdx: idx
  };
}

// Parse Game struct
function parseGame(felts: string[], idx: number): { value: Game; nextIdx: number } {
  console.log(`[parseGame] Starting at idx: ${idx}`);
  
  const id = Number(felts[idx++]);
  
  const player1 = parseContractAddress(felts, idx);
  idx = player1.nextIdx;
  
  const player2 = parseContractAddress(felts, idx);
  idx = player2.nextIdx;
  
  const caps_ids = parseNumberArray(felts, idx);
  idx = caps_ids.nextIdx;
  
  const turn_count = Number(felts[idx++]);
  const over = Number(felts[idx++]) === 1;
  
  const effect_ids = parseNumberArray(felts, idx);
  idx = effect_ids.nextIdx;
  
  const last_action_timestamp = Number(felts[idx++]);
  
  console.log(`[parseGame] Parsed game id=${id}, nextIdx: ${idx}`);
  
  return {
    value: {
      id,
      player1: player1.value,
      player2: player2.value,
      caps_ids: caps_ids.value,
      turn_count,
      over,
      effect_ids: effect_ids.value,
      last_action_timestamp
    },
    nextIdx: idx
  };
}

// Parse array of Effects
function parseEffectArray(felts: string[], idx: number): { value: Effect[]; nextIdx: number } {
  const startIdx = idx;
  const len = Number(felts[idx++]);
  console.log(`[parseEffectArray] idx: ${startIdx}, arrayLength: ${len}`);
  
  if (isNaN(len) || !isFinite(len)) {
    console.error(`[parseEffectArray] Invalid length value: ${len}`);
    throw new RangeError(`Invalid array length: ${len}`);
  }
  
  const arr: Effect[] = [];
  for (let i = 0; i < len; i++) {
    const parsed = parseEffect(felts, idx);
    arr.push(parsed.value);
    idx = parsed.nextIdx;
  }
  console.log(`[parseEffectArray] Parsed ${len} Effects, nextIdx: ${idx}`);
  return { value: arr, nextIdx: idx };
}

// Parse array of Caps
function parseCapArray(felts: string[], idx: number): { value: Cap[]; nextIdx: number } {
  const startIdx = idx;
  const len = Number(felts[idx++]);
  console.log(`[parseCapArray] idx: ${startIdx}, arrayLength: ${len}`);
  
  if (isNaN(len) || !isFinite(len)) {
    console.error(`[parseCapArray] Invalid length value: ${len}`);
    throw new RangeError(`Invalid array length: ${len}`);
  }
  
  const arr: Cap[] = [];
  for (let i = 0; i < len; i++) {
    const parsed = parseCap(felts, idx);
    arr.push(parsed.value);
    idx = parsed.nextIdx;
  }
  console.log(`[parseCapArray] Parsed ${len} Caps, nextIdx: ${idx}`);
  return { value: arr, nextIdx: idx };
}

// Parse (Game, Span<Effect>, Span<Cap>) tuple
export function parseGameState(rawOutput: string): GameState | null {
  console.log(`[parseGameState] Raw output: ${rawOutput}`);
  
  // Process arrays: [] becomes "0", [a b c] becomes "3 a b c"
  let normalized = rawOutput.replace(/\[([^\]]*)\]/g, (match, contents) => {
    const elements = contents.trim();
    if (elements === '') {
      return '0';  // Empty array
    }
    const items = elements.split(/\s+/).filter((s: string) => s.length > 0);
    return `${items.length} ${elements}`;
  });
  
  const felts = normalized.split(/\s+/).filter((s: string) => s.length > 0);
  
  console.log(`[parseGameState] Normalized felts (${felts.length}):`, felts.slice(0, 50));
  
  let idx = 0;
  
  try {
    // Parse Game
    const game = parseGame(felts, idx);
    idx = game.nextIdx;
    
    // Parse Span<Effect>
    const effects = parseEffectArray(felts, idx);
    idx = effects.nextIdx;
    
    // Parse Span<Cap>
    const caps = parseCapArray(felts, idx);
    idx = caps.nextIdx;
    
    console.log(`[parseGameState] Successfully parsed GameState. Final idx: ${idx}, total felts: ${felts.length}`);
    
    return {
      game: game.value,
      effects: effects.value,
      caps: caps.value
    };
  } catch (error) {
    console.error(`[parseGameState] Error parsing:`, error);
    return null;
  }
}