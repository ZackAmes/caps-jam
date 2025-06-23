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
    import Popup from './lib/ui/popup.svelte';
    import Profile from './lib/ui/Profile.svelte';

    
</script>

<main>
  <h1>Caps</h1>

  <Login />
  {#if account.account}
    <Matchmaking />
  {/if}
  {#if caps.selected_cap}
    <CapData capType="selected" />
  {/if}
  {#if caps.inspected_cap}
    <CapData capType="inspected" />
  {/if}
  {#if caps.popup_state.visible}
    <Popup />
  {/if}
  {#if (planetelo.queue_status == 2 || planetelo.current_game_id == planetelo.agent_game_id) && caps.game_state && !caps.game_state.game.over}

    
    <MoveData />
    <div class="game-board-container">
      <Canvas>
        <Game />
      </Canvas>
    </div>
    <button onclick={() => {
      caps.reset_move();
    }}>Reset Move</button>
    <button onclick={() => {
      caps.take_turn();
    }}>Take Turn</button>
    {:else if planetelo.agent_game_id && !caps.game_state}
    <div class="card">
      <button onclick={() => {
        caps.get_game(planetelo.agent_game_id!);
      }}>Get Agent Game</button>
    </div>
  {:else if planetelo.queue_status == 2 && !caps.game_state}
  <div class="card">
    <button onclick={() => {
      caps.get_game(planetelo.planetelo_game_id!);
    }}>Get Game</button>
  </div>
  {:else if planetelo.queue_status == 2 && caps.game_state && caps.game_state.game.over && planetelo.current_game_id}
  {#if planetelo.current_game_id == planetelo.planetelo_game_id}
  <div class="card">
      <button onclick={() => {
        planetelo.handleSettle()
      }}>Settle Match</button>
    </div>
  {/if}
  {:else if planetelo.current_game_id == planetelo.agent_game_id && caps.game_state?.game.over}
  <div class="card">
    <button onclick={() => {
      planetelo.settle_agent_game()
    }}>Settle Game</button>
  </div>
  {/if}

</main>

<style>
  /* Mobile responsive layout adjustments */
  @media (max-width: 720px) {

    
    /* Stack buttons vertically on mobile */
    main > button {
      display: block;
      width: 100%;
      margin: 0.5rem 0;
      max-width: 300px;
      margin-left: auto;
      margin-right: auto;
    }
  }
</style>
