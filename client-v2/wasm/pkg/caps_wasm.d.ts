/* tslint:disable */
/* eslint-disable */
export function start(): void;
export function runCairoProgram(cap_type_id: number): string;
/**
 * Run the test_input Cairo program with a Game struct and ActionType enum
 * 
 * Input format: JSON array where each element is either:
 * - A string/number for a single felt
 * - An array of strings/numbers for an Array<T> field
 * 
 * For Game { id, player1, player2, caps_ids, turn_count, over, effect_ids, last_action_timestamp }
 * + ActionType { variant, x, y }
 */
export function runTestInput(args_js: any[]): string;
/**
 * Run the test_output Cairo program
 * 
 * Input format: Array where each element is either:
 * - A string/number for a single felt
 * - An array of strings/numbers for an Array<T> field
 * 
 * Arguments in order:
 * 1. Game struct fields (id, player1, player2, caps_ids array, turn_count, over, effect_ids array, last_action_timestamp)
 * 2. Cap struct fields (id, owner, location variant, location x, location y, set_id, cap_type, dmg_taken, shield_amt)
 * 3. Effect struct fields (game_id, effect_id, effect_type variant, effect_target variant, remaining_triggers)
 * 
 * Returns: (Game, Cap, Effect)
 */
export function runTestOutput(args_js: any[]): string;
/**
 * Run the simulate Cairo program
 * 
 * Input format: Array where each element is either:
 * - A string/number for a single felt
 * - An array of strings/numbers for an Array<T> field
 * 
 * Arguments in order:
 * 1. Game struct fields
 * 2. Array of Cap structs (as nested array)
 * 3. Array of Effect structs (as nested array)  
 * 4. Array of Action structs (as nested array)
 */
export function runSimulate(args_js: any[]): string;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
  readonly memory: WebAssembly.Memory;
  readonly start: () => void;
  readonly runCairoProgram: (a: number) => [number, number, number, number];
  readonly runTestInput: (a: number, b: number) => [number, number, number, number];
  readonly runTestOutput: (a: number, b: number) => [number, number, number, number];
  readonly runSimulate: (a: number, b: number) => [number, number, number, number];
  readonly __wbindgen_malloc: (a: number, b: number) => number;
  readonly __wbindgen_realloc: (a: number, b: number, c: number, d: number) => number;
  readonly __wbindgen_free: (a: number, b: number, c: number) => void;
  readonly __wbindgen_externrefs: WebAssembly.Table;
  readonly __externref_table_dealloc: (a: number) => void;
  readonly __externref_table_alloc: () => number;
  readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;
/**
* Instantiates the given `module`, which can either be bytes or
* a precompiled `WebAssembly.Module`.
*
* @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
*
* @returns {InitOutput}
*/
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
* If `module_or_path` is {RequestInfo} or {URL}, makes a request and
* for everything else, calls `WebAssembly.instantiate` directly.
*
* @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
*
* @returns {Promise<InitOutput>}
*/
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
