<script lang="ts">
  import { onMount } from 'svelte';
  import { parseCapType, type CapType } from '$lib';
  
  let wasmModule: any;
  let capTypeId = 4;
  let result: CapType | null = null;
  let error: string | null = null;
  let loading = true;
  let rawOutput: string | null = null;

  // Test input state - now tests Location + ActionType enums
  // First enum = reverse-odd: (numVariants - 1 - index) * 2 + 1
  // Second enum = simple: 0, 1, 2, etc.
  // Helper function to calculate reverse-odd variant IDs
  // For n variants: variant i (0-indexed) gets ID = 2n - 1 - 2i
  function reverseOddVariantId(index: number, totalVariants: number): number {
    if (totalVariants <= 2) {
      return index;  // Simple 0-indexed for 2 or fewer variants
    }
    return 2 * totalVariants - 1 - 2 * index;
  }
  
  // Location: 3 variants (Bench, Board, Dead) - reverse-odd
  const locationVariants = ['Bench', 'Board', 'Dead'];
  const locationVariantIds: Record<string, number> = {};
  locationVariants.forEach((v, i) => {
    locationVariantIds[v] = reverseOddVariantId(i, locationVariants.length);
  });
  
  // ActionType: 4 variants (Play, Move, Attack, Ability) - reverse-odd
  const actionVariants = ['Play', 'Move', 'Attack', 'Ability'];
  const actionVariantIds: Record<string, number> = {};
  actionVariants.forEach((v, i) => {
    actionVariantIds[v] = reverseOddVariantId(i, actionVariants.length);
  });
  
  // TargetType: 6 variants - reverse-odd
  const targetTypeVariants = ['None', 'SelfCap', 'TeamCap', 'OpponentCap', 'AnyCap', 'AnySquare'];
  const targetTypeVariantIds: Record<string, number> = {};
  targetTypeVariants.forEach((v, i) => {
    targetTypeVariantIds[v] = reverseOddVariantId(i, targetTypeVariants.length);
  });
  
  // EffectType: 14 variants - reverse-odd
  const effectTypeVariants = ['None', 'DamageBuff', 'Shield', 'Heal', 'DOT', 'MoveBonus', 'AttackBonus', 
    'BonusRange', 'MoveDiscount', 'AttackDiscount', 'AbilityDiscount', 'ExtraEnergy', 'Stun', 'Double'];
  const effectTypeVariantIds: Record<string, number> = {};
  effectTypeVariants.forEach((v, i) => {
    effectTypeVariantIds[v] = reverseOddVariantId(i, effectTypeVariants.length);
  });
  
  // EffectTarget: 3 variants (None, Cap, Square) - reverse-odd
  const effectTargetVariants = ['None', 'Cap', 'Square'];
  const effectTargetVariantIds: Record<string, number> = {};
  effectTargetVariants.forEach((v, i) => {
    effectTargetVariantIds[v] = reverseOddVariantId(i, effectTargetVariants.length);
  });
  
  let testLocationType: 'Bench' | 'Board' | 'Dead' = 'Bench';
  let testLocationX = 3;
  let testLocationY = 3;
  let testLocationVariantId = locationVariantIds['Bench'];  // Reverse-odd: Bench=5, Board=3, Dead=1
  let testActionType: 'Play' | 'Move' | 'Attack' | 'Ability' = 'Play';
  let testActionX = 3;
  let testActionY = 4;
  let testActionVariantId = actionVariantIds['Play'];  // Reverse-odd: Play=7, Move=5, Attack=3, Ability=1
  let testTargetType: 'None' | 'SelfCap' | 'TeamCap' | 'OpponentCap' | 'AnyCap' | 'AnySquare' = 'None';
  let testTargetTypeVariantId = targetTypeVariantIds['None'];  // Reverse-odd: None=11, SelfCap=9, TeamCap=7, OpponentCap=5, AnyCap=3, AnySquare=1
  let testEffectType: 'None' | 'DamageBuff' | 'Shield' | 'Heal' | 'DOT' | 'MoveBonus' | 'AttackBonus' | 'BonusRange' | 'MoveDiscount' | 'AttackDiscount' | 'AbilityDiscount' | 'ExtraEnergy' | 'Stun' | 'Double' = 'None';
  let testEffectTypeVariantId = effectTypeVariantIds['None'];  // Reverse-odd: None=27, DamageBuff=25, ..., Double=1
  let testEffectTypePayload = 0;  // u8 payload for EffectType
  let testEffectTarget: 'None' | 'Cap' | 'Square' = 'None';
  let testEffectTargetVariantId = effectTargetVariantIds['None'];  // Reverse-odd: None=5, Cap=3, Square=1
  let testEffectTargetCapId = '0';  // u64 for Cap variant
  let testEffectTargetSquareX = 0;
  let testEffectTargetSquareY = 0;
  let showAdvanced = false;  // Toggle for variant ID fields
  let testInputResult: { 
    locVariant: number; locX: number; locY: number;
    actionVariant: number; actionX: number; actionY: number;
    targetTypeVariant: number;
    effectTypeVariant: number; effectPayload: number;
    effectTargetVariant: number; effectTargetId: number; effectTargetX: number; effectTargetY: number;
    arrayLen: number;
  } | null = null;
  
  // Test array for empty array testing
  let testArrayValues: string = '';  // Comma-separated values, empty string = empty array
  let testInputError: string | null = null;
  let testInputRaw: string | null = null;

  // Test output state - dedicated variables
  let testOutputGameId = '1';
  let testOutputPlayer1 = '123';
  let testOutputPlayer2 = '456';
  let testOutputTurnCount = '0';
  let testOutputGameOver = false;
  let testOutputLastTimestamp = '0';
  
  let testOutputCapId = '1';
  let testOutputCapOwner = '123';
  let testOutputCapLocationType: 'Bench' | 'Board' | 'Dead' = 'Bench';
  let testOutputCapLocVariant = locationVariantIds['Bench'];
  let testOutputCapLocX = '3';
  let testOutputCapLocY = '3';
  let testOutputCapSetId = '0';
  let testOutputCapType = '0';
  let testOutputCapDmgTaken = '0';
  let testOutputCapShield = '0';
  
  let testOutputEffectGameId = '1';
  let testOutputEffectId = '1';
  let testOutputEffectType: 'None' | 'DamageBuff' | 'Shield' | 'Heal' | 'DOT' | 'MoveBonus' | 'AttackBonus' | 'BonusRange' | 'MoveDiscount' | 'AttackDiscount' | 'AbilityDiscount' | 'ExtraEnergy' | 'Stun' | 'Double' = 'None';
  let testOutputEffectTypeVariant = effectTypeVariantIds['None'];
  let testOutputEffectTypePayload = 0;  // u8 payload for EffectType
  let testOutputEffectTarget: 'None' | 'Cap' | 'Square' = 'None';
  let testOutputEffectTargetVariant = effectTargetVariantIds['None'];
  let testOutputEffectTargetCapId = '0';  // u64 for Cap variant
  let testOutputEffectTargetSquareX = 0;
  let testOutputEffectTargetSquareY = 0;
  let testOutputEffectRemainingTriggers = '0';
  
  let testOutputError: string | null = null;
  let testOutputRaw: string | null = null;
  let testOutputResult: {
    game: { id: string; player1: string; player2: string; turn_count: string; over: boolean; last_timestamp: string };
    cap: { id: string; owner: string; location: { type: string; x?: number; y?: number }; set_id: string; cap_type: string; dmg_taken: string; shield_amt: string };
    effect: { game_id: string; effect_id: string; effect_type: { variant: string; payload?: number }; effect_target: { variant: string; cap_id?: string; x?: number; y?: number }; remaining_triggers: string };
  } | null = null;

  // Simulate test state
  let simulateError: string | null = null;
  let simulateRaw: string | null = null;
  let simulateRunning = false;
  let simulateResult: ParsedSimulateResult | null = null;
  
  // Parsed types for display
  interface ParsedCap {
    id: number;
    owner: string;
    location: { type: string; x?: number; y?: number };
    set_id: number;
    cap_type: number;
    dmg_taken: number;
    shield_amt: number;
    base_health?: number;  // From CapType lookup
  }
  
  interface ParsedGame {
    id: number;
    player1: string;
    player2: string;
    caps_ids: number[];
    turn_count: number;
    over: boolean;
    effect_ids: number[];
    last_action_timestamp: number;
  }
  
  interface ParsedSimulateResult {
    game: ParsedGame;
    effects: any[];  // Simplified for now
    caps: ParsedCap[];
  }
  
  // Parse simulate output: (Game, Array<Effect>, Array<Cap>)
  function parseSimulateOutput(rawOutput: string): ParsedSimulateResult | null {
    try {
      console.log('Raw simulate output:', rawOutput);
      
      // Normalize arrays: [] becomes "0", [a b c] becomes "3 a b c"
      let normalized = rawOutput.replace(/\[([^\]]*)\]/g, (_match, contents) => {
        const elements = contents.trim();
        if (elements === '') return '0';
        const items = elements.split(/\s+/).filter((s: string) => s.length > 0);
        return `${items.length} ${elements}`;
      });
      
      const felts = normalized.split(/\s+/).filter((s: string) => s.length > 0);
      console.log('Normalized felts:', felts);
      
      let idx = 0;
      
      // Parse Game struct: id, player1, player2, caps_ids, turn_count, over, effect_ids, last_action_timestamp
      const gameId = Number(felts[idx++]);
      const player1 = felts[idx++];
      const player2 = felts[idx++];
      
      // caps_ids array
      const capsIdsLen = Number(felts[idx++]);
      const capsIds: number[] = [];
      for (let i = 0; i < capsIdsLen; i++) {
        capsIds.push(Number(felts[idx++]));
      }
      
      const turnCount = Number(felts[idx++]);
      const over = Number(felts[idx++]) === 1;
      
      // effect_ids array
      const effectIdsLen = Number(felts[idx++]);
      const effectIds: number[] = [];
      for (let i = 0; i < effectIdsLen; i++) {
        effectIds.push(Number(felts[idx++]));
      }
      
      const lastTimestamp = Number(felts[idx++]);
      
      const game: ParsedGame = {
        id: gameId,
        player1,
        player2,
        caps_ids: capsIds,
        turn_count: turnCount,
        over,
        effect_ids: effectIds,
        last_action_timestamp: lastTimestamp,
      };
      
      console.log('Parsed Game:', game);
      
      // Parse Effects array (simplified - skip for now, just read length)
      const effectsLen = Number(felts[idx++]);
      console.log('Effects array length:', effectsLen);
      // Skip effect fields for now (each effect has multiple fields)
      // TODO: Parse effects properly
      const effects: any[] = [];
      
      // Parse Caps array
      const capsLen = Number(felts[idx++]);
      console.log('Caps array length:', capsLen);
      
      const fieldsPerCap = 8;  // id, owner, loc_x, loc_y, set_id, cap_type, dmg_taken, shield_amt
      const caps: ParsedCap[] = [];
      
      for (let i = 0; i < capsLen; i++) {
        if (idx + fieldsPerCap > felts.length) {
          console.error(`Not enough felts for cap ${i}`);
          break;
        }
        
        const id = Number(felts[idx++]);
        const owner = felts[idx++];
        const locX = Number(felts[idx++]);
        const locY = Number(felts[idx++]);
        const set_id = Number(felts[idx++]);
        const cap_type = Number(felts[idx++]);
        const dmg_taken = Number(felts[idx++]);
        const shield_amt = Number(felts[idx++]);
        
        let locationType: string;
        if (locX === 0 && locY === 0) {
          locationType = 'Bench/Dead';
        } else {
          locationType = 'Board';
        }
        
        let base_health: number | undefined;
        if (cap_type <= 3) base_health = 10;
        else if (cap_type === 4) base_health = 8;
        
        caps.push({
          id,
          owner,
          location: { 
            type: locationType, 
            x: locationType === 'Board' ? locX : undefined,
            y: locationType === 'Board' ? locY : undefined
          },
          set_id,
          cap_type,
          dmg_taken,
          shield_amt,
          base_health,
        });
      }
      
      return { game, effects, caps };
    } catch (e) {
      console.error('Failed to parse simulate output:', e);
      return null;
    }
  }
  
  // Full simulation state
  // Game fields
  let simGameId = '1';
  let simPlayer1 = '111';
  let simPlayer2 = '222';
  let simTurnCount = '0';
  let simGameOver = false;
  let simLastTimestamp = '0';
  
  // Caps array - simplified to single cap for now
  let simCapId = '1';
  let simCapOwner = '111';
  let simLocationType: 'Bench' | 'Board' | 'Dead' = 'Bench';
  let simCapLocVariant = locationVariantIds['Bench'].toString();  // Use reverse-odd mapping
  let simCapLocX = '0';
  let simCapLocY = '0';
  let simCapSetId = '0';
  let simCapType = '4';
  let simCapDmgTaken = '0';
  let simCapShield = '0';
  
  // Actions array - single action for now
  let simActionCapId = '1';
  let simActionType: 'Play' | 'Move' | 'Attack' | 'Ability' = 'Play';
  let simActionVariant = actionVariantIds['Play'].toString();  // Use reverse-odd mapping
  let simActionX = '3';
  let simActionY = '3';
  // For Move action: direction (0=right, 1=left, 2=up, 3=down) and distance
  let simActionDirection = '0';  // right
  let simActionDistance = '1';
  
  // Effects array - empty for now
  let simEffectsCount = 0;
  
  // Computed: is the action Move? (Move = 5 in reverse-odd for 4 variants)
  $: isMoveAction = simActionVariant === actionVariantIds['Move'].toString();
  
  // Helper to decode hex strings from Cairo panic messages
  function hexToString(hex: string): string {
    // Remove 0x prefix if present
    const clean = hex.startsWith('0x') ? hex.slice(2) : hex;
    let str = '';
    for (let i = 0; i < clean.length; i += 2) {
      const charCode = parseInt(clean.substring(i, i + 2), 16);
      if (charCode > 0 && charCode < 128) {
        str += String.fromCharCode(charCode);
      }
    }
    return str;
  }
  
  // Parse Cairo panic error messages
  function parseCairoError(errorMsg: string): string {
    // Match: Program panicked with [hex1, hex2, hex3, ...]
    const panicMatch = errorMsg.match(/Program panicked with \[([^\]]+)\]/);
    if (!panicMatch) return errorMsg;
    
    const hexValues = panicMatch[1].split(',').map(s => s.trim());
    const decoded: string[] = [];
    
    for (const hex of hexValues) {
      if (hex.startsWith('0x') && hex.length > 4) {
        const str = hexToString(hex);
        if (str.length > 2 && /^[\x20-\x7E]+$/.test(str)) {
          // Looks like readable ASCII
          decoded.push(`"${str}"`);
        } else {
          decoded.push(hex);
        }
      } else {
        decoded.push(hex);
      }
    }
    
    return `Cairo panic: ${decoded.join(', ')}`;
  }

  onMount(async () => {
    try {
      // Dynamically import the WASM module using the alias
      const wasm = await import('$wasm/caps_wasm.js');
      await wasm.default();
      wasmModule = wasm;
      loading = false;
    } catch (e) {
      error = `Failed to load WASM: ${e}`;
      loading = false;
    }
  });

  async function fetchCapType() {
    if (!wasmModule) {
      error = 'WASM module not loaded';
      return;
    }

    error = null;
    result = null;
    rawOutput = null;

    try {
      console.log('Running Cairo program with cap type ID:', capTypeId);
      rawOutput = await wasmModule.runCairoProgram(capTypeId);
      console.log('Raw WASM output:', rawOutput);
      
      if (!rawOutput) {
        error = 'No output from WASM';
        return;
      }
      
      result = parseCapType(rawOutput);
      
      if (!result) {
        error = 'Invalid cap type ID (Option::None returned)';
      }
    } catch (e: any) {
      error = `Error: ${e.message || e}`;
      console.error('Parse error:', e);
    }
  }

  async function runTestInput() {
    if (!wasmModule) {
      testInputError = 'WASM module not loaded';
      return;
    }

    testInputError = null;
    testInputResult = null;
    testInputRaw = null;

    try {
      // Build Location enum serialization
      // Location { Bench, Board(Vec2), Dead }
      // Always send variant + 2 values (padded with 0 if no payload)
      let locationFelts: string[] = [];
      if (testLocationType === 'Board') {
        locationFelts = [testLocationVariantId.toString(), testLocationX.toString(), testLocationY.toString()];
      } else {
        // Bench or Dead - pad with zeros
        locationFelts = [testLocationVariantId.toString(), '0', '0'];
      }

      // Build ActionType enum serialization - always variant + 2 values (Vec2)
      const actionFelts = [
        testActionVariantId.toString(),
        testActionX.toString(),
        testActionY.toString()
      ];
      
      // Build TargetType enum serialization - no payload, just variant
      const targetTypeFelts = [testTargetTypeVariantId.toString()];
      
      // Build EffectType enum serialization - variant + 1 u8 payload
      const effectTypeFelts = [
        testEffectTypeVariantId.toString(),
        testEffectTypePayload.toString()
      ];
      
      // Build EffectTarget enum serialization
      // Pad to match max payload size (Vec2 = 2 values)
      let effectTargetFelts: string[] = [];
      if (testEffectTarget === 'Cap') {
        // Cap variant: variant + u64 (cap_id) + 1 zero to match Vec2 size
        effectTargetFelts = [testEffectTargetVariantId.toString(), testEffectTargetCapId, '0'];
      } else if (testEffectTarget === 'Square') {
        // Square variant: variant + Vec2 (x, y)
        effectTargetFelts = [
          testEffectTargetVariantId.toString(),
          testEffectTargetSquareX.toString(),
          testEffectTargetSquareY.toString()
        ];
      } else {
        // None variant: variant + 2 zeros to match Vec2 size
        effectTargetFelts = [testEffectTargetVariantId.toString(), '0', '0'];
      }
      
      // Build test array: parse comma-separated values, or empty array if empty string
      const testArray: string[] = testArrayValues.trim() === '' 
        ? [] 
        : testArrayValues.split(',').map(v => v.trim()).filter(v => v.length > 0);
      
      // Combine all: location + action + target_type + effect_type + effect_target + test_array
      const serialized: (string | string[])[] = [
        ...locationFelts,
        ...actionFelts,
        ...targetTypeFelts,
        ...effectTypeFelts,
        ...effectTargetFelts,
        testArray  // Array<u64>
      ];
      
      console.log('Test input serialized:', serialized);
      console.log('Location:', testLocationType, 'variant:', testLocationVariantId);
      console.log('Action:', testActionType, 'variant:', testActionVariantId);
      console.log('TargetType:', testTargetType, 'variant:', testTargetTypeVariantId);
      console.log('EffectType:', testEffectType, 'variant:', testEffectTypeVariantId, 'payload:', testEffectTypePayload);
      console.log('EffectTarget:', testEffectTarget, 'variant:', testEffectTargetVariantId);
      
      testInputRaw = await wasmModule.runTestInput(serialized);
      console.log('Raw test_input output:', testInputRaw);
      
      if (!testInputRaw) {
        testInputError = 'No output from WASM';
        return;
      }
      
      // Parse output: (u8, u8, u8, u8, u8, u8, u8, u8, u8, u8, u64, u8, u8, u64)
      // = (loc_variant, loc_x, loc_y, action_variant, action_x, action_y, 
      //    target_type_variant, effect_type_variant, effect_payload, 
      //    effect_target_variant, effect_target_id, effect_target_x, effect_target_y, array_len)
      const felts = testInputRaw.split(/\s+/).filter((s: string) => s.length > 0);
      if (felts.length >= 14) {
        testInputResult = {
          locVariant: Number(felts[0]),
          locX: Number(felts[1]),
          locY: Number(felts[2]),
          actionVariant: Number(felts[3]),
          actionX: Number(felts[4]),
          actionY: Number(felts[5]),
          targetTypeVariant: Number(felts[6]),
          effectTypeVariant: Number(felts[7]),
          effectPayload: Number(felts[8]),
          effectTargetVariant: Number(felts[9]),
          effectTargetId: Number(felts[10]),
          effectTargetX: Number(felts[11]),
          effectTargetY: Number(felts[12]),
          arrayLen: Number(felts[13]),
        };
      } else {
        testInputError = `Expected 14 values, got ${felts.length}`;
      }
    } catch (e: any) {
      const msg = e.message || String(e);
      testInputError = parseCairoError(msg);
      console.error('Test input error:', e);
    }
  }

  async function runTestOutput() {
    if (!wasmModule) {
      testOutputError = 'WASM module not loaded';
      return;
    }

    testOutputError = null;
    testOutputResult = null;
    testOutputRaw = null;

    try {
      // Serialize Game struct: id, player1, player2, caps_ids array, turn_count, over, effect_ids array, last_action_timestamp
      const gameArgs: (string | string[])[] = [
        testOutputGameId,
        testOutputPlayer1,
        testOutputPlayer2,
        [testOutputCapId],  // caps_ids array with single cap
        testOutputTurnCount,
        testOutputGameOver ? '1' : '0',
        [testOutputEffectId],  // effect_ids array with single effect
        testOutputLastTimestamp,
      ];

      // Serialize Cap: id, owner, loc_variant, loc_x, loc_y, set_id, cap_type, dmg_taken, shield_amt
      // Location enum: always send variant + 2 values (Vec2), pad with 0 if no payload
      const capLocX = testOutputCapLocationType === 'Board' ? testOutputCapLocX : '0';
      const capLocY = testOutputCapLocationType === 'Board' ? testOutputCapLocY : '0';
      const capFields: string[] = [
        testOutputCapId,
        testOutputCapOwner,
        testOutputCapLocVariant.toString(),
        capLocX,
        capLocY,
        testOutputCapSetId,
        testOutputCapType,
        testOutputCapDmgTaken,
        testOutputCapShield,
      ];

      // Serialize Effect: game_id, effect_id, effect_type enum, effect_target enum, remaining_triggers
      // EffectType: all variants have u8 payload (1 value), so pad to 1 value
      // EffectTarget: longest payload is Vec2 (2 values) for Square, so pad all to 2 values
      const effectTypeFelts: string[] = [
        testOutputEffectTypeVariant.toString(),
        testOutputEffectTypePayload.toString(),  // u8 payload
      ];
      
      // EffectTarget enum serialization - pad to max payload size (Vec2 = 2 values)
      // Max payload: Square has Vec2 (2 values), Cap has u64 (1 value), None has 0 values
      // When padding variants with payloads, repeat the payload value instead of padding with zeros
      let effectTargetFelts: string[] = [];
      if (testOutputEffectTarget === 'Cap') {
        // Cap variant: variant + u64 (cap_id) + repeat cap_id for padding = variant + 2 payload values
        effectTargetFelts = [
          testOutputEffectTargetVariant.toString(),
          testOutputEffectTargetCapId,
          testOutputEffectTargetCapId,  // Repeat cap_id for padding (not zero)
        ];
      } else if (testOutputEffectTarget === 'Square') {
        // Square variant: variant + Vec2 (x, y) = variant + 2 payload values (already at max)
        effectTargetFelts = [
          testOutputEffectTargetVariant.toString(),
          testOutputEffectTargetSquareX.toString(),
          testOutputEffectTargetSquareY.toString(),
        ];
      } else {
        // None variant: variant + 2 zeros padding = variant + 2 payload values (no payload to repeat)
        effectTargetFelts = [
          testOutputEffectTargetVariant.toString(),
          '0',
          '0',
        ];
      }
      
      const effectFields: string[] = [
        testOutputEffectGameId,
        testOutputEffectId,
        ...effectTypeFelts,      // variant + payload (2 values)
        ...effectTargetFelts,    // variant + payload (3 values, but we'll flatten)
        testOutputEffectRemainingTriggers,
      ];

      // Full input: game fields + cap fields + effect fields
      const serialized: (string | string[])[] = [
        ...gameArgs,      // Game struct fields (8 args: singles + arrays)
        ...capFields,     // Cap struct fields (9 args)
        ...effectFields,  // Effect struct fields (5 args)
      ];

      console.log('Test output serialized input:', serialized);
      
      testOutputRaw = await wasmModule.runTestOutput(serialized);
      console.log('Raw test_output output:', testOutputRaw);
      
      if (testOutputRaw) {
        // Parse new format: SERIALIZED: ... \n RETURN_VALUES: \n [0] value1 \n [1] value2 ...
        const lines = testOutputRaw.split('\n').map(l => l.trim()).filter(l => l.length > 0);
        
        let serializedLine = '';
        const returnValues: { index: number; value: string }[] = [];
        let inReturnValues = false;
        
        for (const line of lines) {
          if (line.startsWith('SERIALIZED: ')) {
            serializedLine = line.substring('SERIALIZED: '.length);
          } else if (line === 'RETURN_VALUES:') {
            inReturnValues = true;
          } else if (inReturnValues && line.startsWith('[') && line.includes(']')) {
            const match = line.match(/\[(\d+)\]\s+(.+)/);
            if (match) {
              returnValues.push({ index: Number(match[1]), value: match[2] });
            }
          }
        }
        
        console.log('Serialized output:', serializedLine);
        console.log('Return values:', returnValues);
        
        // Parse serialized output for structure (arrays, etc.)
        let normalized = serializedLine.replace(/\[([^\]]*)\]/g, (_match, contents) => {
          const elements = contents.trim();
          if (elements === '') return '0';
          const items = elements.split(/\s+/).filter((s: string) => s.length > 0);
          return `${items.length} ${elements}`;
        });
        
        const felts = normalized.split(/\s+/).filter((s: string) => s.length > 0);
        console.log('Normalized felts from serialized:', felts);
        
        // Return values structure:
        // Game: id(0), player1(1), player2(2), caps_ids_ptr(3), caps_ids_len(4), turn_count(5), over(6), effect_ids_ptr(7), effect_ids_len(8), last_timestamp(9)
        // Cap: id(10), owner(11), loc_variant(12), loc_x(13), loc_y(14), set_id(15), cap_type(16), dmg_taken(17), shield_amt(18)
        // Effect: game_id(19), effect_id(20), effect_type_variant(21), effect_target_variant(22), remaining_triggers(23)
        
        // Parse Game from serialized output
        let idx = 0;
        const gameId = felts[idx++];
        const player1 = felts[idx++];
        const player2 = felts[idx++];
        const capsIdsLen = Number(felts[idx++]);
        const capsIds: string[] = [];
        for (let i = 0; i < capsIdsLen; i++) {
          capsIds.push(felts[idx++]);
        }
        const turnCount = felts[idx++];
        const over = felts[idx++] === '1' || felts[idx - 1] === 'true';
        const effectIdsLen = Number(felts[idx++]);
        const effectIds: string[] = [];
        for (let i = 0; i < effectIdsLen; i++) {
          effectIds.push(felts[idx++]);
        }
        const lastTimestamp = felts[idx++];
        
        // Parse Cap from serialized output, but use return values for enum variant
        const capId = felts[idx++];
        const capOwner = felts[idx++];
        // Get loc_variant from return values (index 12) - skip relocatable addresses
        const locVariantRaw = returnValues.find(rv => rv.index === 12);
        const locVariant = locVariantRaw && !locVariantRaw.value.includes(':') ? locVariantRaw.value : felts[idx++];
        const locX = felts[idx++];
        const locY = felts[idx++];
        const setId = felts[idx++];
        const capType = felts[idx++];
        const dmgTaken = felts[idx++];
        const shieldAmt = felts[idx++];
        
        // Parse Effect from serialized output, but use return values for enum variants
        // Return values structure for Effect:
        // game_id(19), effect_id(20), effect_type_variant(21), effect_type_payload(22),
        // effect_target_variant(23), effect_target_payload1(24), effect_target_payload2(25), remaining_triggers(26)
        const effectGameId = felts[idx++];
        const effectId = felts[idx++];
        
        // EffectType: variant + u8 payload (2 values total)
        // Get variant from return values (index 21) - skip relocatable addresses
        const effectTypeVariantRaw = returnValues.find(rv => rv.index === 21);
        const effectTypeVariant = effectTypeVariantRaw && !effectTypeVariantRaw.value.includes(':') ? effectTypeVariantRaw.value : felts[idx++];
        const effectTypePayload = Number(felts[idx++]);  // u8 payload
        
        // EffectTarget: variant + 2 payload values (3 values total: variant + 2 values for Vec2 padding)
        // Get variant from return values (index 23) - skip relocatable addresses
        const effectTargetVariantRaw = returnValues.find(rv => rv.index === 23);
        const effectTargetVariant = effectTargetVariantRaw && !effectTargetVariantRaw.value.includes(':') ? effectTargetVariantRaw.value : felts[idx++];
        const effectTargetPayload1 = felts[idx++];  // First payload value
        const effectTargetPayload2 = felts[idx++];  // Second payload value (padding for None/Cap)
        
        const remainingTriggers = felts[idx++];
        
        // Parse EffectTarget based on variant
        let effectTargetType: string;
        let effectTargetCapId: string | undefined;
        let effectTargetX: number | undefined;
        let effectTargetY: number | undefined;
        const effectTargetVariantNum = Number(effectTargetVariant);
        if (effectTargetVariantNum === 5) {  // None
          effectTargetType = 'None';
        } else if (effectTargetVariantNum === 3) {  // Cap
          effectTargetType = 'Cap';
          effectTargetCapId = effectTargetPayload1;
        } else if (effectTargetVariantNum === 1) {  // Square
          effectTargetType = 'Square';
          effectTargetX = Number(effectTargetPayload1);
          effectTargetY = Number(effectTargetPayload2);
        } else {
          effectTargetType = `Unknown(${effectTargetVariant})`;
        }
        
        // Parse EffectType variant name
        let effectTypeName: string;
        const effectTypeVariantNum = Number(effectTypeVariant);
        // Reverse-odd mapping for 14 variants: None=27, DamageBuff=25, ..., Double=1
        const effectTypeMap: Record<number, string> = {
          27: 'None', 25: 'DamageBuff', 23: 'Shield', 21: 'Heal', 19: 'DOT',
          17: 'MoveBonus', 15: 'AttackBonus', 13: 'BonusRange', 11: 'MoveDiscount',
          9: 'AttackDiscount', 7: 'AbilityDiscount', 5: 'ExtraEnergy', 3: 'Stun', 1: 'Double'
        };
        effectTypeName = effectTypeMap[effectTypeVariantNum] || `Unknown(${effectTypeVariant})`;
        
        // Determine location type from variant ID (reverse-odd: Bench=5, Board=3, Dead=1)
        let locationType: string;
        const locVariantNum = Number(locVariant);
        if (locVariantNum === 5) {
          locationType = 'Bench';
        } else if (locVariantNum === 3) {
          locationType = 'Board';
        } else if (locVariantNum === 1) {
          locationType = 'Dead';
        } else {
          locationType = `Unknown(${locVariant})`;
        }
        
        testOutputResult = {
          game: {
            id: gameId,
            player1: player1,
            player2: player2,
            turn_count: turnCount,
            over: over,
            last_timestamp: lastTimestamp,
          },
          cap: {
            id: capId,
            owner: capOwner,
            location: {
              type: locationType,
              x: locationType === 'Board' ? Number(locX) : undefined,
              y: locationType === 'Board' ? Number(locY) : undefined,
            },
            set_id: setId,
            cap_type: capType,
            dmg_taken: dmgTaken,
            shield_amt: shieldAmt,
          },
          effect: {
            game_id: effectGameId,
            effect_id: effectId,
            effect_type: {
              variant: effectTypeName,
              payload: effectTypePayload,
            },
            effect_target: {
              variant: effectTargetType,
              cap_id: effectTargetCapId,
              x: effectTargetX,
              y: effectTargetY,
            },
            remaining_triggers: remainingTriggers,
          },
        };
      } else {
        testOutputError = 'No output from WASM';
      }
    } catch (e: any) {
      const msg = e.message || String(e);
      testOutputError = parseCairoError(msg);
      console.error('Test output error:', e);
    }
  }

  async function runSimulate() {
    if (!wasmModule) {
      simulateError = 'WASM module not loaded';
      return;
    }

    simulateError = null;
    simulateRaw = null;
    simulateResult = null;
    simulateRunning = true;

    try {
      // Serialize Game struct: id, player1, player2, caps_ids, turn_count, over, effect_ids, last_action_timestamp
      const gameArgs: (string | string[])[] = [
        simGameId,
        simPlayer1,
        simPlayer2,
        [simCapId],  // caps_ids array
        simTurnCount,
        simGameOver ? '1' : '0',
        [],  // effect_ids array (empty for now)
        simLastTimestamp,
      ];

      // Serialize Cap: id, owner, loc_variant, loc_x, loc_y, set_id, cap_type, dmg_taken, shield_amt
      // Location enum: always send variant + 2 values (Vec2), pad with 0 if no payload
      const capLocX = simLocationType === 'Board' ? simCapLocX : '0';
      const capLocY = simLocationType === 'Board' ? simCapLocY : '0';
      const capsFlat: string[] = [
        simCapId,
        simCapOwner,
        simCapLocVariant,
        capLocX,
        capLocY,
        simCapSetId,
        simCapType,
        simCapDmgTaken,
        simCapShield,
      ];

      // Serialize Action: cap_id, action_variant, x, y (or direction, distance for Move)
      const actionFelts: string[] = [
        simActionCapId,
        simActionVariant,
        isMoveAction ? simActionDirection : simActionX,
        isMoveAction ? simActionDistance : simActionY,
      ];

      // Effects array - empty for now
      const effectsFlat: string[] = [];

      // Full input: game fields + caps array + effects array + actions array
      const serialized: (string | string[])[] = [
        ...gameArgs,      // Game struct fields (8 args: singles + arrays)
        capsFlat,         // Array<Cap>
        effectsFlat,      // Array<Effect>
        actionFelts,      // Array<Action>
      ];

      console.log('Simulate serialized input:', serialized);
      console.log('Serialized length:', serialized.length);
      console.log('Game args:', gameArgs);
      console.log('Game args length:', gameArgs.length);
      console.log('Caps flat:', capsFlat, 'length:', capsFlat.length);
      console.log('Effects flat:', effectsFlat, 'length:', effectsFlat.length);
      console.log('Action felts:', actionFelts, 'length:', actionFelts.length);
      
      // Log each argument type
      serialized.forEach((arg, i) => {
        if (Array.isArray(arg)) {
          console.log(`Arg ${i}: Array with ${arg.length} elements:`, arg);
        } else {
          console.log(`Arg ${i}: Single value:`, arg);
        }
      });

      simulateRaw = await wasmModule.runSimulate(serialized);
      console.log('Simulate raw output:', simulateRaw);
      
      if (simulateRaw) {
        simulateResult = parseSimulateOutput(simulateRaw);
      }
      
    } catch (e: any) {
      const msg = e.message || String(e);
      simulateError = parseCairoError(msg);
      console.error('Simulate error:', e);
    } finally {
      simulateRunning = false;
    }
  }
</script>

<div class="container">
  <h1>Cairo WASM Demo - Complex Types</h1>
  
  {#if loading}
    <p>Loading WASM module...</p>
  {:else}
    <!-- Test 1: Get Cap Type (output only) -->
    <section class="test-section">
      <h2>Test 1: Cap Type Lookup (Output)</h2>
      <p class="description">Tests deserializing complex output from Cairo</p>
      
      {#if error}
        <div class="error">{error}</div>
        {#if rawOutput}
          <details open>
            <summary>Raw WASM Output</summary>
            <pre class="raw-output">{rawOutput}</pre>
          </details>
        {/if}
      {/if}
      
      <div class="controls">
        <label>
          Cap Type ID (0-23):
          <input type="number" bind:value={capTypeId} min="0" max="23" />
        </label>
        <button on:click={fetchCapType}>Get Cap Type</button>
      </div>

      {#if result}
        <div class="result">
          <h3>{result.name}</h3>
          <div class="stats">
            <p><strong>ID:</strong> {result.id}</p>
            <p><strong>Description:</strong> {result.description}</p>
            <p><strong>Health:</strong> {result.base_health}</p>
            <p><strong>Attack Damage:</strong> {result.attack_dmg}</p>
            <p><strong>Move Cost:</strong> {result.move_cost}</p>
            <p><strong>Attack Cost:</strong> {result.attack_cost}</p>
            <p><strong>Ability Cost:</strong> {result.ability_cost}</p>
            <p><strong>Ability Target:</strong> {result.ability_target}</p>
          </div>
        </div>
      {/if}
    </section>

    <hr />

    <!-- Test 2: Enum Variant Discovery -->
    <section class="test-section">
      <div class="section-header">
        <div>
          <h2>Test 2: Enum Variant Discovery</h2>
          <p class="description">Find the correct enum variant IDs for Location and ActionType</p>
        </div>
        <label class="toggle-label">
          <input type="checkbox" bind:checked={showAdvanced} />
          Show variant IDs
        </label>
      </div>
      
      {#if testInputError}
        <div class="error">{testInputError}</div>
      {/if}

      <div class="input-grid">
        <div class="input-group">
          <h4>Location Enum</h4>
          <label>
            Type:
            <select bind:value={testLocationType} on:change={() => {
              testLocationVariantId = locationVariantIds[testLocationType];
            }}>
              <option value="Bench">Bench</option>
              <option value="Board">Board</option>
              <option value="Dead">Dead</option>
            </select>
          </label>
          {#if testLocationType === 'Board'}
            <label>
              Board X: <input type="number" bind:value={testLocationX} min="0" max="6" />
            </label>
            <label>
              Board Y: <input type="number" bind:value={testLocationY} min="0" max="6" />
            </label>
          {/if}
          {#if showAdvanced}
            <label>
              Variant ID: <input type="number" bind:value={testLocationVariantId} min="0" max="10" />
              <span class="hint">Bench=5, Board=3, Dead=1 (reverse-odd, 3 variants)</span>
            </label>
          {/if}
        </div>

        <div class="input-group">
          <h4>ActionType Enum</h4>
          <label>
            Type:
            <select bind:value={testActionType} on:change={() => {
              testActionVariantId = actionVariantIds[testActionType];
            }}>
              <option value="Play">Play</option>
              <option value="Move">Move</option>
              <option value="Attack">Attack</option>
              <option value="Ability">Ability</option>
            </select>
          </label>
          <label>
            Target X: <input type="number" bind:value={testActionX} min="0" max="6" />
          </label>
          <label>
            Target Y: <input type="number" bind:value={testActionY} min="0" max="6" />
          </label>
          {#if showAdvanced}
            <label>
              Variant ID: <input type="number" bind:value={testActionVariantId} min="0" max="10" />
              <span class="hint">Play=7, Move=5, Attack=3, Ability=1 (reverse-odd, 4 variants)</span>
            </label>
          {/if}
        </div>

        <div class="input-group">
          <h4>TargetType Enum</h4>
          <label>
            Type:
            <select bind:value={testTargetType} on:change={() => {
              testTargetTypeVariantId = targetTypeVariantIds[testTargetType];
            }}>
              <option value="None">None</option>
              <option value="SelfCap">SelfCap</option>
              <option value="TeamCap">TeamCap</option>
              <option value="OpponentCap">OpponentCap</option>
              <option value="AnyCap">AnyCap</option>
              <option value="AnySquare">AnySquare</option>
            </select>
          </label>
          {#if showAdvanced}
            <label>
              Variant ID: <input type="number" bind:value={testTargetTypeVariantId} min="0" max="10" />
              <span class="hint">None=11, SelfCap=9, TeamCap=7, OpponentCap=5, AnyCap=3, AnySquare=1 (reverse-odd, 6 variants)</span>
            </label>
          {/if}
        </div>

        <div class="input-group">
          <h4>EffectType Enum</h4>
          <label>
            Type:
            <select bind:value={testEffectType} on:change={() => {
              testEffectTypeVariantId = effectTypeVariantIds[testEffectType];
            }}>
              <option value="None">None</option>
              <option value="DamageBuff">DamageBuff</option>
              <option value="Shield">Shield</option>
              <option value="Heal">Heal</option>
              <option value="DOT">DOT</option>
              <option value="MoveBonus">MoveBonus</option>
              <option value="AttackBonus">AttackBonus</option>
              <option value="BonusRange">BonusRange</option>
              <option value="MoveDiscount">MoveDiscount</option>
              <option value="AttackDiscount">AttackDiscount</option>
              <option value="AbilityDiscount">AbilityDiscount</option>
              <option value="ExtraEnergy">ExtraEnergy</option>
              <option value="Stun">Stun</option>
              <option value="Double">Double</option>
            </select>
          </label>
          <label>
            Payload (u8): <input type="number" bind:value={testEffectTypePayload} min="0" max="255" />
          </label>
          {#if showAdvanced}
            <label>
              Variant ID: <input type="number" bind:value={testEffectTypeVariantId} min="0" max="20" />
            </label>
          {/if}
        </div>

        <div class="input-group">
          <h4>EffectTarget Enum</h4>
          <label>
            Type:
            <select bind:value={testEffectTarget} on:change={() => {
              testEffectTargetVariantId = effectTargetVariantIds[testEffectTarget];
            }}>
              <option value="None">None</option>
              <option value="Cap">Cap</option>
              <option value="Square">Square</option>
            </select>
          </label>
          {#if testEffectTarget === 'Cap'}
            <label>
              Cap ID (u64): <input type="text" bind:value={testEffectTargetCapId} />
            </label>
          {:else if testEffectTarget === 'Square'}
            <label>
              Square X: <input type="number" bind:value={testEffectTargetSquareX} min="0" max="6" />
            </label>
            <label>
              Square Y: <input type="number" bind:value={testEffectTargetSquareY} min="0" max="6" />
            </label>
          {/if}
          {#if showAdvanced}
            <label>
              Variant ID: <input type="number" bind:value={testEffectTargetVariantId} min="0" max="10" />
              <span class="hint">None=5, Cap=3, Square=1 (reverse-odd, 3 variants)</span>
            </label>
          {/if}
        </div>

        <div class="input-group">
          <h4>Test Array (Array&lt;u64&gt;)</h4>
          <label>
            Values (comma-separated, leave empty for empty array):
            <input type="text" bind:value={testArrayValues} placeholder="e.g., 1, 2, 3" />
          </label>
          <span class="hint">Empty string = empty array. Use this to test empty array serialization.</span>
        </div>
      </div>

      <button on:click={runTestInput}>Run Test Input</button>

      {#if testInputResult}
        <div class="result success">
          <h3>✅ Parsed by Cairo</h3>
          <div class="stats">
            <h4>Location</h4>
            <p><strong>Variant:</strong> {testInputResult.locVariant} (0=Bench, 1=Board, 2=Dead)</p>
            <p><strong>X:</strong> {testInputResult.locX}</p>
            <p><strong>Y:</strong> {testInputResult.locY}</p>
            
            <h4>ActionType</h4>
            <p><strong>Variant:</strong> {testInputResult.actionVariant} (0=Play, 1=Move, 2=Attack, 3=Ability)</p>
            <p><strong>X:</strong> {testInputResult.actionX}</p>
            <p><strong>Y:</strong> {testInputResult.actionY}</p>
            
            <h4>TargetType</h4>
            <p><strong>Variant:</strong> {testInputResult.targetTypeVariant} (0=None, 1=SelfCap, 2=TeamCap, 3=OpponentCap, 4=AnyCap, 5=AnySquare)</p>
            
            <h4>EffectType</h4>
            <p><strong>Variant:</strong> {testInputResult.effectTypeVariant} (0=None, 1=DamageBuff, ...)</p>
            <p><strong>Payload:</strong> {testInputResult.effectPayload}</p>
            
            <h4>EffectTarget</h4>
            <p><strong>Variant:</strong> {testInputResult.effectTargetVariant} (0=None, 1=Cap, 2=Square)</p>
            {#if testInputResult.effectTargetVariant === 1}
              <p><strong>Cap ID:</strong> {testInputResult.effectTargetId}</p>
            {:else if testInputResult.effectTargetVariant === 2}
              <p><strong>Square X:</strong> {testInputResult.effectTargetX}</p>
              <p><strong>Square Y:</strong> {testInputResult.effectTargetY}</p>
            {/if}
            
            <h4>Test Array</h4>
            <p><strong>Array Length:</strong> {testInputResult.arrayLen}</p>
            <p class="explanation">If length matches your input array, empty arrays are working correctly!</p>
          </div>
          <p class="explanation">If these match your inputs, you found the right variant IDs!</p>
        </div>
        
        <details>
          <summary>Raw Output</summary>
          <pre class="raw-output">{testInputRaw}</pre>
        </details>
      {/if}
    </section>

    <hr />

    <!-- Test 2.5: Output Serialization Test -->
    <section class="test-section">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div>
          <h2>Test 2.5: Output Serialization Test</h2>
          <p class="description">Test output serialization: main(game: Game, cap: Cap, effect: Effect) -&gt; (Game, Cap, Effect)</p>
        </div>
        <label class="toggle-label">
          <input type="checkbox" bind:checked={showAdvanced} />
          Show variant IDs
        </label>
      </div>
      
      {#if testOutputError}
        <div class="error">{testOutputError}</div>
      {/if}

      <div class="input-grid">
        <div class="input-group">
          <h4>Game</h4>
          <label>id: <input type="text" bind:value={testOutputGameId} /></label>
          <label>player1: <input type="text" bind:value={testOutputPlayer1} /></label>
          <label>player2: <input type="text" bind:value={testOutputPlayer2} /></label>
          <label>turn_count: <input type="text" bind:value={testOutputTurnCount} /></label>
          <label>over: <input type="checkbox" bind:checked={testOutputGameOver} /></label>
          <label>last_action_timestamp: <input type="text" bind:value={testOutputLastTimestamp} /></label>
        </div>

        <div class="input-group">
          <h4>Cap</h4>
          <label>id: <input type="text" bind:value={testOutputCapId} /></label>
          <label>owner: <input type="text" bind:value={testOutputCapOwner} /></label>
          <label>
            Location:
            <select bind:value={testOutputCapLocationType} on:change={() => {
              testOutputCapLocVariant = locationVariantIds[testOutputCapLocationType];
            }}>
              <option value="Bench">Bench</option>
              <option value="Board">Board</option>
              <option value="Dead">Dead</option>
            </select>
            <span class="hint">Bench=5, Board=3, Dead=1 (reverse-odd, 3 variants)</span>
          </label>
          {#if testOutputCapLocationType === 'Board'}
            <label>loc_x: <input type="text" bind:value={testOutputCapLocX} /></label>
            <label>loc_y: <input type="text" bind:value={testOutputCapLocY} /></label>
          {:else}
            <label>loc_x: <input type="text" bind:value={testOutputCapLocX} disabled /></label>
            <label>loc_y: <input type="text" bind:value={testOutputCapLocY} disabled /></label>
          {/if}
          {#if showAdvanced}
            <label>loc_variant: <input type="text" bind:value={testOutputCapLocVariant} /></label>
          {/if}
          <label>set_id: <input type="text" bind:value={testOutputCapSetId} /></label>
          <label>cap_type: <input type="text" bind:value={testOutputCapType} /></label>
          <label>dmg_taken: <input type="text" bind:value={testOutputCapDmgTaken} /></label>
          <label>shield_amt: <input type="text" bind:value={testOutputCapShield} /></label>
        </div>

        <div class="input-group">
          <h4>Effect</h4>
          <label>game_id: <input type="text" bind:value={testOutputEffectGameId} /></label>
          <label>effect_id: <input type="text" bind:value={testOutputEffectId} /></label>
          <label>
            EffectType:
            <select bind:value={testOutputEffectType} on:change={() => {
              testOutputEffectTypeVariant = effectTypeVariantIds[testOutputEffectType];
            }}>
              <option value="None">None</option>
              <option value="DamageBuff">DamageBuff</option>
              <option value="Shield">Shield</option>
              <option value="Heal">Heal</option>
              <option value="DOT">DOT</option>
              <option value="MoveBonus">MoveBonus</option>
              <option value="AttackBonus">AttackBonus</option>
              <option value="BonusRange">BonusRange</option>
              <option value="MoveDiscount">MoveDiscount</option>
              <option value="AttackDiscount">AttackDiscount</option>
              <option value="AbilityDiscount">AbilityDiscount</option>
              <option value="ExtraEnergy">ExtraEnergy</option>
              <option value="Stun">Stun</option>
              <option value="Double">Double</option>
            </select>
          </label>
          <label>
            EffectType Payload (u8): <input type="number" bind:value={testOutputEffectTypePayload} min="0" max="255" />
          </label>
          {#if showAdvanced}
            <label>effect_type variant: <input type="text" bind:value={testOutputEffectTypeVariant} /></label>
          {/if}
          <label>
            EffectTarget:
            <select bind:value={testOutputEffectTarget} on:change={() => {
              testOutputEffectTargetVariant = effectTargetVariantIds[testOutputEffectTarget];
            }}>
              <option value="None">None</option>
              <option value="Cap">Cap</option>
              <option value="Square">Square</option>
            </select>
          </label>
          {#if testOutputEffectTarget === 'Cap'}
            <label>Cap ID (u64): <input type="text" bind:value={testOutputEffectTargetCapId} /></label>
          {:else if testOutputEffectTarget === 'Square'}
            <label>Square X: <input type="number" bind:value={testOutputEffectTargetSquareX} min="0" max="6" /></label>
            <label>Square Y: <input type="number" bind:value={testOutputEffectTargetSquareY} min="0" max="6" /></label>
          {/if}
          {#if showAdvanced}
            <label>effect_target variant: <input type="text" bind:value={testOutputEffectTargetVariant} /></label>
          {/if}
          <label>remaining_triggers: <input type="text" bind:value={testOutputEffectRemainingTriggers} /></label>
        </div>
      </div>

      <button on:click={runTestOutput}>Run Test Output</button>

      {#if testOutputResult}
        <div class="result success">
          <h3>✅ Output Serialization Complete</h3>
          
          <div class="game-result">
            <h4>Game</h4>
            <div class="stats">
              <p><strong>ID:</strong> {testOutputResult.game.id}</p>
              <p><strong>Player 1:</strong> {testOutputResult.game.player1}</p>
              <p><strong>Player 2:</strong> {testOutputResult.game.player2}</p>
              <p><strong>Turn Count:</strong> {testOutputResult.game.turn_count}</p>
              <p><strong>Over:</strong> {testOutputResult.game.over ? 'Yes' : 'No'}</p>
              <p><strong>Last Action Timestamp:</strong> {testOutputResult.game.last_timestamp}</p>
            </div>
          </div>

          <div class="cap-result">
            <h4>Cap</h4>
            <div class="stats">
              <p><strong>ID:</strong> {testOutputResult.cap.id}</p>
              <p><strong>Owner:</strong> {testOutputResult.cap.owner}</p>
              <p><strong>Location:</strong> {testOutputResult.cap.location.type}{testOutputResult.cap.location.type === 'Board' ? ` (${testOutputResult.cap.location.x}, ${testOutputResult.cap.location.y})` : ''}</p>
              <p><strong>Set ID:</strong> {testOutputResult.cap.set_id}</p>
              <p><strong>Cap Type:</strong> {testOutputResult.cap.cap_type}</p>
              <p><strong>Damage Taken:</strong> {testOutputResult.cap.dmg_taken}</p>
              <p><strong>Shield:</strong> {testOutputResult.cap.shield_amt}</p>
            </div>
          </div>

          <div class="effect-result">
            <h4>Effect</h4>
            <div class="stats">
              <p><strong>Game ID:</strong> {testOutputResult.effect.game_id}</p>
              <p><strong>Effect ID:</strong> {testOutputResult.effect.effect_id}</p>
              <p><strong>EffectType:</strong> {testOutputResult.effect.effect_type.variant}{testOutputResult.effect.effect_type.payload !== undefined ? ` (payload: ${testOutputResult.effect.effect_type.payload})` : ''}</p>
              <p><strong>EffectTarget:</strong> {testOutputResult.effect.effect_target.variant}
                {#if testOutputResult.effect.effect_target.cap_id !== undefined}
                  (Cap ID: {testOutputResult.effect.effect_target.cap_id})
                {:else if testOutputResult.effect.effect_target.x !== undefined && testOutputResult.effect.effect_target.y !== undefined}
                  (Square: {testOutputResult.effect.effect_target.x}, {testOutputResult.effect.effect_target.y})
                {/if}
              </p>
              <p><strong>Remaining Triggers:</strong> {testOutputResult.effect.remaining_triggers}</p>
            </div>
          </div>
          
          <p class="explanation">If these match your inputs, output serialization is working correctly!</p>
        </div>
      {/if}
      
      {#if testOutputRaw}
        <div class="result">
          <h3>Raw Output</h3>
          <pre class="raw-output">{testOutputRaw}</pre>
        </div>
      {/if}
    </section>

    <hr />

    <!-- Test 3: Full Simulate -->
    <section class="test-section">
      <h2>Test 3: Full Game Simulation</h2>
      <p class="description">Full simulation: main(game: Game, caps: Array&lt;Cap&gt;, effects: Array&lt;Effect&gt;, turn: Array&lt;Action&gt;)</p>
      
      {#if simulateError}
        <div class="error">{simulateError}</div>
      {/if}

      <div class="input-grid">
        <div class="input-group">
          <h4>Game</h4>
          <label>id: <input type="text" bind:value={simGameId} /></label>
          <label>player1: <input type="text" bind:value={simPlayer1} /></label>
          <label>player2: <input type="text" bind:value={simPlayer2} /></label>
          <label>turn_count: <input type="text" bind:value={simTurnCount} /></label>
          <label>over: <input type="checkbox" bind:checked={simGameOver} /></label>
          <label>last_action_timestamp: <input type="text" bind:value={simLastTimestamp} /></label>
        </div>

        <div class="input-group">
          <h4>Cap (Array[0])</h4>
          <label>id: <input type="text" bind:value={simCapId} /></label>
          <label>owner: <input type="text" bind:value={simCapOwner} /></label>
          <label>
            Location:
            <select bind:value={simLocationType} on:change={() => {
              simCapLocVariant = locationVariantIds[simLocationType].toString();
            }}>
              <option value="Bench">Bench</option>
              <option value="Board">Board</option>
              <option value="Dead">Dead</option>
            </select>
            <span class="hint">Bench=5, Board=3, Dead=1 (reverse-odd, 3 variants)</span>
          </label>
          {#if simLocationType === 'Board'}
            <label>loc_x: <input type="text" bind:value={simCapLocX} /></label>
            <label>loc_y: <input type="text" bind:value={simCapLocY} /></label>
          {:else}
            <label>loc_x: <input type="text" bind:value={simCapLocX} disabled /></label>
            <label>loc_y: <input type="text" bind:value={simCapLocY} disabled /></label>
          {/if}
          {#if showAdvanced}
            <label>loc_variant: <input type="text" bind:value={simCapLocVariant} /></label>
          {/if}
          <label>set_id: <input type="text" bind:value={simCapSetId} /></label>
          <label>cap_type: <input type="text" bind:value={simCapType} /></label>
          <label>dmg_taken: <input type="text" bind:value={simCapDmgTaken} /></label>
          <label>shield_amt: <input type="text" bind:value={simCapShield} /></label>
        </div>

        <div class="input-group">
          <h4>Action (Array[0])</h4>
          <label>cap_id: <input type="text" bind:value={simActionCapId} /></label>
          <label>
            Action Type:
            <select bind:value={simActionType} on:change={() => {
              simActionVariant = actionVariantIds[simActionType].toString();
            }}>
              <option value="Play">Play</option>
              <option value="Move">Move</option>
              <option value="Attack">Attack</option>
              <option value="Ability">Ability</option>
            </select>
            <span class="hint">Play=7, Move=5, Attack=3, Ability=1 (reverse-odd, 4 variants)</span>
          </label>
          {#if showAdvanced}
            <label>action_variant: <input type="text" bind:value={simActionVariant} /></label>
          {/if}
          {#if isMoveAction}
            <label>direction: <input type="text" bind:value={simActionDirection} />
              <span class="hint">0=right, 1=left, 2=up, 3=down</span>
            </label>
            <label>distance: <input type="text" bind:value={simActionDistance} /></label>
          {:else}
            <label>x: <input type="text" bind:value={simActionX} /></label>
            <label>y: <input type="text" bind:value={simActionY} /></label>
          {/if}
        </div>
      </div>

      <div class="calldata-preview">
        <h4>Serialized Calldata</h4>
        <pre class="raw-output">Game: id={simGameId}, player1={simPlayer1}, player2={simPlayer2}, turn_count={simTurnCount}, over={simGameOver}
Caps: [{simCapId}, {simCapOwner}, {simCapLocVariant}, {simCapLocX}, {simCapLocY}, {simCapSetId}, {simCapType}, {simCapDmgTaken}, {simCapShield}]
Effects: [] (empty)
Actions: [{simActionCapId}, {simActionVariant}, {isMoveAction ? simActionDirection : simActionX}, {isMoveAction ? simActionDistance : simActionY}]</pre>
      </div>

      <button on:click={runSimulate} disabled={simulateRunning}>
        {simulateRunning ? 'Running...' : 'Run Simulate'}
      </button>

      {#if simulateResult}
        <div class="result success">
          <h3>✅ Simulation Complete</h3>
          
          <div class="game-result">
            <h4>Game State</h4>
            <div class="stats">
              <p><strong>ID:</strong> {simulateResult.game.id}</p>
              <p><strong>Player 1:</strong> {simulateResult.game.player1}</p>
              <p><strong>Player 2:</strong> {simulateResult.game.player2}</p>
              <p><strong>Turn Count:</strong> {simulateResult.game.turn_count}</p>
              <p><strong>Over:</strong> {simulateResult.game.over ? 'Yes' : 'No'}</p>
              <p><strong>Cap IDs:</strong> [{simulateResult.game.caps_ids.join(', ')}]</p>
              <p><strong>Effect IDs:</strong> [{simulateResult.game.effect_ids.join(', ')}]</p>
            </div>
          </div>

          <div class="effects-result">
            <h4>Effects ({simulateResult.effects.length})</h4>
            {#if simulateResult.effects.length === 0}
              <p>No effects</p>
            {:else}
              <p>Effects parsing not yet implemented</p>
            {/if}
          </div>

          <div class="caps-result">
            <h4>Caps ({simulateResult.caps.length})</h4>
            {#each simulateResult.caps as cap, i}
              <div class="cap-result">
                <h5>Cap {i + 1}</h5>
                <div class="stats">
                  <p><strong>ID:</strong> {cap.id}</p>
                  <p><strong>Owner:</strong> {cap.owner}</p>
                  <p><strong>Location:</strong> {cap.location.type}{cap.location.type === 'Board' ? ` (${cap.location.x}, ${cap.location.y})` : ''}</p>
                  <p><strong>Set ID:</strong> {cap.set_id}</p>
                  <p><strong>Cap Type:</strong> {cap.cap_type}</p>
                  {#if cap.base_health !== undefined}
                    <p><strong>Health:</strong> {cap.base_health - cap.dmg_taken}/{cap.base_health} (dmg: {cap.dmg_taken})</p>
                  {:else}
                    <p><strong>Damage Taken:</strong> {cap.dmg_taken}</p>
                  {/if}
                  <p><strong>Shield:</strong> {cap.shield_amt}</p>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
      
      {#if simulateRaw}
        <details>
          <summary>Raw Output</summary>
          <pre class="raw-output">{simulateRaw}</pre>
        </details>
      {/if}
    </section>
  {/if}
</div>

<style>
  .container {
    max-width: 900px;
    margin: 2rem auto;
    padding: 1rem;
    font-family: system-ui, -apple-system, sans-serif;
  }

  h1 {
    color: #1a1a2e;
    border-bottom: 3px solid #4CAF50;
    padding-bottom: 0.5rem;
  }

  .test-section {
    margin: 2rem 0;
    padding: 1.5rem;
    background: #fafafa;
    border-radius: 12px;
    border: 1px solid #e0e0e0;
  }

  .test-section h2 {
    margin-top: 0;
    color: #333;
    font-size: 1.3rem;
  }

  .description {
    color: #666;
    font-size: 0.9rem;
    margin-bottom: 1rem;
  }

  hr {
    border: none;
    border-top: 1px solid #ddd;
    margin: 2rem 0;
  }

  .controls {
    display: flex;
    gap: 1rem;
    align-items: flex-end;
    margin: 1rem 0;
  }

  .input-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin: 1rem 0;
  }

  .input-group {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    border: 1px solid #e0e0e0;
  }

  .input-group h4 {
    margin: 0 0 1rem 0;
    color: #555;
    font-size: 0.95rem;
  }

  .simulate-info {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    border: 1px solid #e0e0e0;
    margin-bottom: 1rem;
  }

  .simulate-info h4 {
    margin: 0 0 0.5rem 0;
    color: #555;
  }

  .simulate-info ul {
    margin: 0;
    padding-left: 1.5rem;
  }

  .simulate-info li {
    margin: 0.25rem 0;
    font-size: 0.9rem;
  }

  label {
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
    margin-bottom: 0.75rem;
    font-size: 0.9rem;
    color: #444;
  }

  input[type="number"], select {
    padding: 0.5rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    width: 100%;
    box-sizing: border-box;
  }

  input[type="checkbox"] {
    width: auto;
  }

  button {
    padding: 0.75rem 1.5rem;
    background: #4CAF50;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 600;
    font-size: 0.95rem;
    transition: background 0.2s;
  }

  button:hover {
    background: #43a047;
  }

  .error {
    padding: 1rem;
    background: #ffebee;
    color: #c62828;
    border: 1px solid #ef9a9a;
    border-radius: 6px;
    margin: 1rem 0;
  }

  .result {
    margin-top: 1.5rem;
    padding: 1.5rem;
    background: white;
    border-radius: 8px;
    border: 1px solid #e0e0e0;
  }

  .result.success {
    background: #e8f5e9;
    border-color: #a5d6a7;
  }

  .result h3 {
    margin-top: 0;
    color: #333;
  }

  .explanation {
    color: #666;
    font-size: 0.85rem;
    font-style: italic;
  }

  .hint {
    color: #888;
    font-size: 0.8rem;
    font-style: italic;
  }

  .calldata-preview {
    margin: 1rem 0;
    padding: 1rem;
    background: #f5f5f5;
    border-radius: 8px;
  }

  .calldata-preview h4 {
    margin: 0 0 0.5rem 0;
    font-size: 0.9rem;
    color: #555;
  }

  .input-group input[type="text"] {
    font-family: 'Monaco', 'Menlo', monospace;
    font-size: 0.85rem;
  }

  .cap-result {
    background: white;
    border: 1px solid #c8e6c9;
    border-radius: 8px;
    padding: 1rem;
    margin: 0.5rem 0;
  }

  .cap-result h4 {
    margin: 0 0 0.5rem 0;
    color: #2e7d32;
    font-size: 0.95rem;
  }

  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 1rem;
  }

  .section-header h2 {
    margin: 0;
  }

  .section-header .description {
    margin: 0.25rem 0 0 0;
  }

  .toggle-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.85rem;
    color: #666;
    cursor: pointer;
    white-space: nowrap;
  }

  .toggle-label input[type="checkbox"] {
    width: auto;
    margin: 0;
  }

  .stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 0.5rem;
  }

  .stats p {
    margin: 0.3rem 0;
    font-size: 0.9rem;
  }

  details {
    margin-top: 1rem;
  }

  summary {
    cursor: pointer;
    font-weight: 600;
    padding: 0.5rem;
    background: #f5f5f5;
    border-radius: 4px;
    font-size: 0.9rem;
  }

  .raw-output {
    background: #263238;
    color: #aed581;
    padding: 1rem;
    border-radius: 6px;
    overflow-x: auto;
    font-size: 0.8rem;
    font-family: 'Monaco', 'Menlo', monospace;
  }
</style>

