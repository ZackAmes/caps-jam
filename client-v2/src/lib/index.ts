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

// TargetType enum names
const TargetTypeNames = ['None', 'SelfCap', 'TeamCap', 'OpponentCap', 'AnyCap', 'AnySquare'];

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