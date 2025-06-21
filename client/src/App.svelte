<script lang="ts">
  import svelteLogo from './assets/svelte.svg'
  import viteLogo from '/vite.svg'
  import Login from './lib/Login.svelte'
  import Game from './lib/Game.svelte'
  import { planetelo } from './lib/stores/planetelo.svelte'
  import { Canvas } from '@threlte/core'
  import { caps } from './lib/stores/caps.svelte'
  import { account } from './lib/stores/account.svelte'
    import Matchmaking from './lib/Matchmaking.svelte';
    import CapData from './lib/ui/cap_data.svelte';
    import MoveData from './lib/ui/move_data.svelte';
  $effect(() => {
    console.log(planetelo.queue_status)
 //   planetelo.update_status();
    if (planetelo.queue_status == 2) {
  //    caps.get_game();
    }
  });


</script>

<main>
  <h1>Caps</h1>


  <Login />
  <Matchmaking />
  {#if caps.selected_cap}
    <CapData />
  {/if}
  {#if planetelo.queue_status == 2 && caps.game_state && !caps.game_state.game.over}

    <button onclick={() => {
      caps.reset_move();
    }}>Reset Move</button>
    <button onclick={() => {
      caps.take_turn();
    }}>Take Turn</button>
    <MoveData />
    <div class="game-container">
      <Canvas>
        <Game />
      </Canvas>
    </div>
  {:else if planetelo.queue_status == 2 && !caps.game_state}
  <div class="card">
    <button onclick={() => {
      caps.get_game();
    }}>Get Game</button>
  </div>
  {:else if planetelo.queue_status == 2 && caps.game_state && caps.game_state.game.over}
    <div class="card">
      <button onclick={() => {
        planetelo.handleSettle()
      }}>Settle Match</button>
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
