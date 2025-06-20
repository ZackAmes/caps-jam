<script lang="ts">
  import svelteLogo from './assets/svelte.svg'
  import viteLogo from '/vite.svg'
  import Login from './lib/Login.svelte'
  import Game from './lib/Game.svelte'
  import { planetelo } from './lib/planetelo.svelte'
  import { Canvas } from '@threlte/core'
  import { caps } from './lib/caps.svelte'

  $effect(() => {
    console.log(planetelo.queue_status)
    planetelo.update_status();
    caps.get_game();
  });
</script>

<main>
  <h1>Caps</h1>

  <div class="card">
    <Login />
    <button onclick={() => {
      caps.get_game();
    }}>Get Game</button>
  </div>
  {#if planetelo.queue_status == 2}
    <div class="game-container">
      <Canvas>
        <Game />
      </Canvas>
    </div>
  {/if}

</main>

<style>
  .game-container {
    display: flex;
    justify-content: center;
    align-items: center;
    width: min(90vw, 90vh, 600px);
    aspect-ratio: 1;
    padding: 1rem;
    margin: 2rem auto;
    border: 1px solid #ccc;
  }
</style>
