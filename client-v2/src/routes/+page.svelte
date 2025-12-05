<script lang="ts">
  import { onMount } from 'svelte';
  import { parseCapType, serializeTestInput, parseTestInputOutput, type CapType, type Game, type ActionType } from '$lib';
  
  let wasmModule: any;
  let capTypeId = 4;
  let result: CapType | null = null;
  let error: string | null = null;
  let loading = true;
  let rawOutput: string | null = null;

  // Test input state
  let testGame: Game = {
    id: 1,
    player1: '123456789',
    player2: '987654321',
    caps_ids: [1, 2, 3],
    turn_count: 5,
    over: false,
    effect_ids: [10, 20],
    last_action_timestamp: 1000
  };
  let testActionType: 'Play' | 'Move' | 'Attack' | 'Ability' = 'Move';
  let testActionX = 3;
  let testActionY = 4;
  let testInputResult: { result: number; x: number; y: number } | null = null;
  let testInputError: string | null = null;
  let testInputRaw: string | null = null;

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
      const action: ActionType = { 
        type: testActionType, 
        pos: { x: testActionX, y: testActionY } 
      };
      
      const serialized = serializeTestInput(testGame, action);
      console.log('Serialized input felts:', serialized);
      
      testInputRaw = await wasmModule.runTestInput(serialized);
      console.log('Raw test_input output:', testInputRaw);
      
      if (!testInputRaw) {
        testInputError = 'No output from WASM';
        return;
      }
      
      testInputResult = parseTestInputOutput(testInputRaw);
      
      if (!testInputResult) {
        testInputError = 'Failed to parse output';
      }
    } catch (e: any) {
      testInputError = `Error: ${e.message || e}`;
      console.error('Test input error:', e);
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

    <!-- Test 2: Complex Input -->
    <section class="test-section">
      <h2>Test 2: Complex Input (Game + Enum)</h2>
      <p class="description">Tests serializing complex types to Cairo</p>
      
      {#if testInputError}
        <div class="error">{testInputError}</div>
      {/if}

      <div class="input-grid">
        <div class="input-group">
          <h4>Game State</h4>
          <label>
            ID: <input type="number" bind:value={testGame.id} />
          </label>
          <label>
            Turn Count: <input type="number" bind:value={testGame.turn_count} />
          </label>
          <label>
            Over: <input type="checkbox" bind:checked={testGame.over} />
          </label>
          <label>
            Timestamp: <input type="number" bind:value={testGame.last_action_timestamp} />
          </label>
        </div>

        <div class="input-group">
          <h4>Action</h4>
          <label>
            Type:
            <select bind:value={testActionType}>
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
        </div>
      </div>

      <button on:click={runTestInput}>Run Test Input</button>

      {#if testInputResult}
        <div class="result success">
          <h3>✅ Result</h3>
          <p><strong>Computed Value:</strong> {testInputResult.result}</p>
          <p class="explanation">(turn_count {testGame.turn_count} + action_value {testInputResult.result - testGame.turn_count} = {testInputResult.result})</p>
          <p><strong>Target X:</strong> {testInputResult.x}</p>
          <p><strong>Target Y:</strong> {testInputResult.y}</p>
        </div>
        
        <details>
          <summary>Raw Output</summary>
          <pre class="raw-output">{testInputRaw}</pre>
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
