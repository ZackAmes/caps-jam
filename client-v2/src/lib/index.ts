// WASM Cairo Type Deserialization Helpers

export interface Vec2 {
  x: number;
  y: number;
}

export interface CapType {
  id: number;
  name: string;
  description: string;
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

// Helper to convert hex string to text
function hexToString(hex: string): string {
  let str = '';
  for (let i = 0; i < hex.length; i += 2) {
    str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
  }
  return str;
}

// Helper to parse ByteArray from felts
function parseByteArray(felts: string[], idx: number): { value: string; nextIdx: number } {
  const numFullWords = Number(felts[idx++]);
  const words: string[] = [];
  for (let i = 0; i < numFullWords; i++) {
    words.push(felts[idx++]);
  }
  const pendingWord = felts[idx++];
  const pendingWordLen = Number(felts[idx++]);
  
  let result = '';
  words.forEach(word => {
    const hex = BigInt(word).toString(16).padStart(62, '0');
    result += hexToString(hex);
  });
  if (pendingWordLen > 0) {
    const hex = BigInt(pendingWord).toString(16).padStart(pendingWordLen * 2, '0');
    result += hexToString(hex);
  }
  return { value: result, nextIdx: idx };
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
  const len = Number(felts[idx++]);
  const arr: Vec2[] = [];
  for (let i = 0; i < len; i++) {
    const parsed = parseVec2(felts, idx);
    arr.push(parsed.value);
    idx = parsed.nextIdx;
  }
  return { value: arr, nextIdx: idx };
}

// TargetType enum names
const TargetTypeNames = ['None', 'SelfCap', 'TeamCap', 'OpponentCap', 'AnyCap', 'AnySquare'];

// Parse CapType from serialized output
export function parseCapType(rawOutput: string): CapType | null {
  // Split the raw output into felts
  const felts = rawOutput.trim().split(/\s+/);
  
  let idx = 0;
  
  // Parse Option enum - 0 = None, 1 = Some
  const optionVariant = Number(felts[idx++]);
  if (optionVariant === 0) {
    return null;
  }
  
  // Parse CapType struct
  const id = Number(felts[idx++]);
  
  const name = parseByteArray(felts, idx);
  idx = name.nextIdx;
  
  const description = parseByteArray(felts, idx);
  idx = description.nextIdx;
  
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

// Re-export for convenience
export { CairoByteArray } from "starknet";
