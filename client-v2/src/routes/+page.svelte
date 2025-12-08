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
  const locationVariantIds = { Bench: 5, Board: 3, Dead: 1 };  // First enum (reverse-odd)
  // Theory: odd variant count uses reverse-odd, even uses simple
  // ActionType now has 3 variants (odd) - test if reverse-odd: Play=5, Move=3, Attack=1
  const actionVariantIds = { Play: 5, Move: 3, Attack: 1 };  // 3 variants (odd) - reverse-odd?
  
  let testLocationType: 'Bench' | 'Board' | 'Dead' = 'Bench';
  let testLocationX = 3;
  let testLocationY = 3;
  let testLocationVariantId = 5;  // First enum: reverse-odd
  let testActionType: 'Play' | 'Move' | 'Attack' = 'Play';
  let testActionX = 3;
  let testActionY = 4;
  let testActionVariantId = 5;  // Now 3 variants (odd) - try reverse-odd: Play=5, Move=3, Attack=1
  let showAdvanced = false;  // Toggle for variant ID fields
  let testInputResult: { locType: number; locX: number; locY: number; actType: number; actX: number } | null = null;
  let testInputError: string | null = null;
  let testInputRaw: string | null = null;

  // Simulate test state
  let simulateError: string | null = null;
  let simulateRaw: string | null = null;
  let simulateRunning = false;
  let simulateResult: ParsedCap[] | null = null;
  
  // Parsed Cap type for display
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
  
  // Parse simulate output: Array<Cap>
  function parseSimulateOutput(rawOutput: string): ParsedCap[] | null {
    try {
      console.log('Raw simulate output:', rawOutput);
      console.log('Raw output length:', rawOutput.length);
      
      // Check if output contains brackets (array format)
      const bracketMatch = rawOutput.match(/\[([^\]]*)\]/);
      let felts: string[];
      
      if (bracketMatch) {
        // Array format: [a b c d ...] or [length a b c d ...]
        const contents = bracketMatch[1].trim();
        felts = contents.split(/\s+/).filter((s: string) => s.length > 0);
        console.log('Array contents (from brackets):', felts, 'Count:', felts.length);
      } else {
        // Space-separated format
        felts = rawOutput.split(/\s+/).filter((s: string) => s.length > 0);
        console.log('Space-separated felts:', felts, 'Count:', felts.length);
      }
      
      if (felts.length === 0) {
        console.error('No felts found in output');
        return [];
      }
      
      // Cap has 8 fields: id, owner, loc_x, loc_y, set_id, cap_type, dmg_taken, shield_amt
      // Location enum variant is NOT in output, just the x, y values
      const fieldsPerCap = 8;
      
      // Try different parsing strategies
      let startIdx = 0;
      let numCaps = 0;
      
      // Strategy 1: Check if first value is a length prefix (total field count or cap count)
      const firstValue = Number(felts[0]);
      const remainingAfterLength = felts.length - 1;
      
      if (remainingAfterLength > 0 && remainingAfterLength % fieldsPerCap === 0) {
        const possibleCaps = remainingAfterLength / fieldsPerCap;
        // Length could be total fields (remainingAfterLength) or cap count (possibleCaps)
        if (firstValue === remainingAfterLength || firstValue === possibleCaps) {
          console.log('Strategy 1: Detected length prefix:', firstValue, 'Caps:', possibleCaps);
          startIdx = 1;
          numCaps = possibleCaps;
        }
      }
      
      // Strategy 2: No length prefix, just divide by fieldsPerCap
      if (numCaps === 0) {
        if (felts.length % fieldsPerCap === 0) {
          numCaps = felts.length / fieldsPerCap;
          console.log('Strategy 2: No length prefix, direct division. Caps:', numCaps);
        } else {
          console.warn('Strategy 3: Felts length', felts.length, 'does not divide evenly by', fieldsPerCap);
          // Try to parse what we can
          numCaps = Math.floor(felts.length / fieldsPerCap);
          console.log('Attempting to parse', numCaps, 'caps with', felts.length, 'felts');
        }
      }
      
      console.log('Final: Start idx:', startIdx, 'Total felts:', felts.length, 'Fields per cap:', fieldsPerCap, 'Caps:', numCaps);
      
      if (numCaps === 0) {
        console.error('Could not determine number of caps. Felts:', felts);
        return [];
      }
      
      const caps: ParsedCap[] = [];
      let idx = startIdx;
      
      for (let i = 0; i < numCaps; i++) {
        if (idx + fieldsPerCap > felts.length) {
          console.error(`Not enough felts for cap ${i}. Need ${fieldsPerCap} but only have ${felts.length - idx} remaining.`);
          break;
        }
        
        console.log(`Parsing cap ${i} starting at idx ${idx}`);
        const id = Number(felts[idx++]);
        const owner = felts[idx++];
        // Location enum: no variant in output, just the values (x, y)
        // For Bench/Dead: x=0, y=0 (or maybe not present?)
        // For Board: x, y coordinates
        const locX = Number(felts[idx++]);
        const locY = Number(felts[idx++]);
        const set_id = Number(felts[idx++]);
        const cap_type = Number(felts[idx++]);
        const dmg_taken = Number(felts[idx++]);
        const shield_amt = Number(felts[idx++]);  // Might be 8th field or missing
        
        console.log(`Cap ${i}: id=${id}, owner=${owner}, loc=(${locX},${locY}), set_id=${set_id}, type=${cap_type}, dmg=${dmg_taken}, shield=${shield_amt}`);
        
        // Infer location type from values
        // If both x and y are 0, it's likely Bench or Dead (can't distinguish without variant)
        // If either is non-zero, it's Board
        let locationType: string;
        if (locX === 0 && locY === 0) {
          locationType = 'Bench/Dead';  // Can't tell which without variant
        } else {
          locationType = 'Board';
        }
        
        // Basic CapType lookup for base_health (simplified - just first few types)
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
      
      return caps;
    } catch (e) {
      console.error('Failed to parse simulate output:', e);
      return null;
    }
  }
  
  // Editable calldata for simulate
  // Cap fields: id, owner, loc_variant, loc_x, loc_y, set_id, cap_type, dmg_taken, shield_amt
  let simCapId = '1';
  let simCapOwner = '111';
  let simCapLocVariant = '5';  // Bench (1st enum: reverse-odd)
  let simCapLocX = '0';
  let simCapLocY = '0';
  let simCapSetId = '0';
  let simCapType = '4';
  let simCapDmgTaken = '0';
  let simCapShield = '0';
  // Action fields: cap_id, action_variant, x, y
  let simActionCapId = '1';
  let simActionVariant = '5';  // 3 variants (odd): Play=5, Move=3, Attack=1?
  let simActionX = '3';
  let simActionY = '3';
  // Caller
  let simCaller = '111';
  
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

      // Build ActionType enum serialization
      // ActionType { Play(Vec2), Move(Vec2) }
      // Always sends variant + 2 values
      const actionFelts = [
        testActionVariantId.toString(),
        testActionX.toString(),
        testActionY.toString()
      ];
      
      // Combine: location felts + action felts (all as singles) = 6 total
      const serialized: (string | string[])[] = [...locationFelts, ...actionFelts];
      
      console.log('Test input serialized:', serialized);
      console.log('Location:', testLocationType, 'variant:', testLocationVariantId);
      console.log('Action:', testActionType, 'variant:', testActionVariantId);
      
      testInputRaw = await wasmModule.runTestInput(serialized);
      console.log('Raw test_input output:', testInputRaw);
      
      if (!testInputRaw) {
        testInputError = 'No output from WASM';
        return;
      }
      
      // Parse output: (u8, u8, u8, u8, u8) = (loc_type, loc_x, loc_y, action_type, target_x)
      const felts = testInputRaw.split(/\s+/).filter((s: string) => s.length > 0);
      if (felts.length >= 5) {
        testInputResult = {
          locType: Number(felts[0]),
          locX: Number(felts[1]),
          locY: Number(felts[2]),
          actType: Number(felts[3]),
          actX: Number(felts[4]),
        };
      } else {
        testInputError = `Expected 5 values, got ${felts.length}`;
      }
    } catch (e: any) {
      const msg = e.message || String(e);
      testInputError = parseCairoError(msg);
      console.error('Test input error:', e);
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
      // Build serialized input from editable fields
      // Cap { id: u64, owner: felt252, location: Location, set_id: u64, cap_type: u16, dmg_taken: u16, shield_amt: u16 }
      const capsFlat: string[] = [
        simCapId,
        simCapOwner,
        simCapLocVariant,
        simCapLocX,
        simCapLocY,
        simCapSetId,
        simCapType,
        simCapDmgTaken,
        simCapShield,
      ];

      // Action { cap_id: u64, action_type: ActionType }
      const actionFelts: string[] = [
        simActionCapId,
        simActionVariant,
        simActionX,
        simActionY,
      ];

      const serialized: (string | string[])[] = [
        capsFlat,         // Array<Cap>
        ...actionFelts,   // Action fields as singles
        simCaller,        // caller felt252
      ];

      console.log('Simulate serialized input:', serialized);
      console.log('Caps flat:', capsFlat);
      console.log('Action felts:', actionFelts);
      console.log('Caller:', simCaller);

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
              <span class="hint">Bench=5, Board=3, Dead=1 (1st: reverse-odd)</span>
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
              <span class="hint">3 variants (odd): Play=5, Move=3, Attack=1?</span>
            </label>
          {/if}
        </div>
      </div>

      <button on:click={runTestInput}>Run Test Input</button>

      {#if testInputResult}
        <div class="result success">
          <h3>✅ Parsed by Cairo</h3>
          <div class="stats">
            <p><strong>Location Type:</strong> {testInputResult.locType} (0=Bench, 1=Board, 2=Dead)</p>
            <p><strong>Location X:</strong> {testInputResult.locX}</p>
            <p><strong>Location Y:</strong> {testInputResult.locY}</p>
            <p><strong>Action Type:</strong> {testInputResult.actType} (0=Play, 1=Move)</p>
            <p><strong>Action X:</strong> {testInputResult.actX}</p>
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

    <!-- Test 3: Full Simulate -->
    <section class="test-section">
      <h2>Test 3: Full Game Simulation</h2>
      <p class="description">Editable calldata for simulate(caps, action, caller)</p>
      
      {#if simulateError}
        <div class="error">{simulateError}</div>
      {/if}

      <div class="input-grid">
        <div class="input-group">
          <h4>Cap (Array[0])</h4>
          <label>id: <input type="text" bind:value={simCapId} /></label>
          <label>owner: <input type="text" bind:value={simCapOwner} /></label>
          <label>loc_variant: <input type="text" bind:value={simCapLocVariant} />
            <span class="hint">Bench=5, Board=3, Dead=1 (1st: reverse-odd)</span>
          </label>
          <label>loc_x: <input type="text" bind:value={simCapLocX} /></label>
          <label>loc_y: <input type="text" bind:value={simCapLocY} /></label>
          <label>set_id: <input type="text" bind:value={simCapSetId} /></label>
          <label>cap_type: <input type="text" bind:value={simCapType} /></label>
          <label>dmg_taken: <input type="text" bind:value={simCapDmgTaken} /></label>
          <label>shield_amt: <input type="text" bind:value={simCapShield} /></label>
        </div>

        <div class="input-group">
          <h4>Action</h4>
          <label>cap_id: <input type="text" bind:value={simActionCapId} /></label>
          <label>action_variant: <input type="text" bind:value={simActionVariant} />
            <span class="hint">3 variants: Play=5, Move=3, Attack=1?</span>
          </label>
          <label>x: <input type="text" bind:value={simActionX} /></label>
          <label>y: <input type="text" bind:value={simActionY} /></label>
          <h4>Caller</h4>
          <label>caller: <input type="text" bind:value={simCaller} /></label>
        </div>
      </div>

      <div class="calldata-preview">
        <h4>Serialized Calldata</h4>
        <pre class="raw-output">caps: [{simCapId}, {simCapOwner}, {simCapLocVariant}, {simCapLocX}, {simCapLocY}, {simCapSetId}, {simCapType}, {simCapDmgTaken}, {simCapShield}]
action: [{simActionCapId}, {simActionVariant}, {simActionX}, {simActionY}]
caller: {simCaller}</pre>
      </div>

      <button on:click={runSimulate} disabled={simulateRunning}>
        {simulateRunning ? 'Running...' : 'Run Simulate'}
      </button>

      {#if simulateResult}
        <div class="result success">
          <h3>✅ Simulation Complete - {simulateResult.length} Cap(s)</h3>
          {#each simulateResult as cap, i}
            <div class="cap-result">
              <h4>Cap {i + 1}</h4>
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
