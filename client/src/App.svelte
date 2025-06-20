<script lang="ts">
  import svelteLogo from './assets/svelte.svg'
  import viteLogo from '/vite.svg'
  import Login from './lib/Login.svelte'
  import Game from './lib/Game.svelte'
  import { planetelo } from './lib/planetelo.svelte'
  import { Canvas } from '@threlte/core'
</script>

<main>
  <h1>Caps</h1>

  <div class="card">
    <Login />
  </div>
  {#if planetelo.queue_status == 2}
    <div class="game-container">
      <Canvas>
        <Game />
      </Canvas>
    </div>
  {/if}

  <p>
    Check out <a href="https://github.com/sveltejs/kit#readme" target="_blank" rel="noreferrer">SvelteKit</a>, the official Svelte app framework powered by Vite!
  </p>

  <p class="read-the-docs">
    Click on the Vite and Svelte logos to learn more
  </p>
</main>

<style>
  .logo {
    height: 6em;
    padding: 1.5em;
    will-change: filter;
    transition: filter 300ms;
  }
  .logo:hover {
    filter: drop-shadow(0 0 2em #646cffaa);
  }
  .logo.svelte:hover {
    filter: drop-shadow(0 0 2em #ff3e00aa);
  }
  .game-container {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100vw;
    height: 70vh;
    padding: 1rem;
    margin: 2rem 0;
  }
  .read-the-docs {
    color: #888;
  }
</style>
