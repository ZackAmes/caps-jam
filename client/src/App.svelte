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
    import TeamSelector from './lib/ui/TeamSelector.svelte';

    
</script>

<main>
  <div class="header">
    <h1>Caps</h1>
    <div class="user-controls">
      <Login />
      {#if account.account}
      <TeamSelector />
      {/if}
    </div>
  </div>

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

  .header {
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    align-items: center;
    width: 100%;
    margin-bottom: 1rem;
  }

  .header > h1 {
    grid-column: 1;
    justify-self: start;
  }

  .user-controls {
    grid-column: 2;
    justify-self: center;
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  @media (max-width: 768px) {
    .header {
      grid-template-columns: 1fr;
      gap: 1rem;
    }
    .header > h1, .user-controls {
      grid-column: 1;
      justify-self: center;
    }
  }
</style>
