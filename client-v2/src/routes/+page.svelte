<script lang="ts">
  import { onMount } from 'svelte';
  import { parseCapType, type CapType } from '$lib';
  
  let wasmModule: any;
  let capTypeId = 4;
  let result: CapType | null = null;
  let error: string | null = null;
  let loading = true;
  let rawOutput: string | null = null;

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
</script>

<div class="container">
  <h1>Cairo WASM Demo - Complex Types</h1>
  
  {#if loading}
    <p>Loading WASM module...</p>
  {:else if error}
    <div class="error">
      {error}
    </div>
    {#if rawOutput}
      <details open>
        <summary>Raw WASM Output (for debugging)</summary>
        <pre style="background: #333; color: #0f0; padding: 1rem; overflow-x: auto; font-size: 0.8rem;">{rawOutput}</pre>
      </details>
    {/if}
  {:else}
    <div class="controls">
      <label>
        Cap Type ID (0-4):
        <input type="number" bind:value={capTypeId} min="0" max="4" />
      </label>
      <button on:click={fetchCapType}>Get Cap Type</button>
    </div>

    {#if result}
      <div class="result">
        <h2>{result.name}</h2>
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

        <div class="ranges">
          <div>
            <h3>Move Range</h3>
            <p>X: {result.move_range.x}, Y: {result.move_range.y}</p>
          </div>

          <div>
            <h3>Attack Range</h3>
            <ul>
              {#each result.attack_range as vec}
                <li>({vec.x}, {vec.y})</li>
              {/each}
            </ul>
          </div>

          <div>
            <h3>Ability Range</h3>
            <ul>
              {#each result.ability_range as vec}
                <li>({vec.x}, {vec.y})</li>
              {/each}
            </ul>
          </div>
        </div>

        <div class="ability">
          <h3>Ability Description</h3>
          <p>{result.ability_description}</p>
        </div>

        <details>
          <summary>Raw JSON</summary>
          <pre>{JSON.stringify(result, null, 2)}</pre>
        </details>
      </div>
    {/if}
  {/if}
</div>

<style>
  .container {
    max-width: 800px;
    margin: 2rem auto;
    padding: 1rem;
  }

  .controls {
    display: flex;
    gap: 1rem;
    align-items: center;
    margin: 2rem 0;
  }

  label {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  input[type="number"] {
    padding: 0.5rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    width: 100px;
  }

  button {
    padding: 0.5rem 1rem;
    background: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  button:hover {
    background: #45a049;
  }

  .error {
    padding: 1rem;
    background: #f44336;
    color: white;
    border-radius: 4px;
    margin: 1rem 0;
  }

  .result {
    margin-top: 2rem;
    padding: 1.5rem;
    background: #f5f5f5;
    border-radius: 8px;
  }

  .result h2 {
    margin-top: 0;
    color: #333;
  }

  .stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin: 1rem 0;
  }

  .stats p {
    margin: 0.5rem 0;
  }

  .ranges {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin: 1.5rem 0;
  }

  .ranges h3 {
    margin-top: 0;
    font-size: 1rem;
    color: #666;
  }

  .ranges ul {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .ranges li {
    padding: 0.25rem 0;
  }

  .ability {
    margin-top: 1.5rem;
    padding: 1rem;
    background: white;
    border-radius: 4px;
  }

  .ability h3 {
    margin-top: 0;
    font-size: 1rem;
    color: #666;
  }

  details {
    margin-top: 1.5rem;
  }

  summary {
    cursor: pointer;
    font-weight: bold;
    padding: 0.5rem;
    background: white;
    border-radius: 4px;
  }

  pre {
    background: white;
    padding: 1rem;
    border-radius: 4px;
    overflow-x: auto;
  }
</style>
