<script lang="ts">
  import { planetelo } from "./stores/planetelo.svelte";
  import { account } from "./stores/account.svelte";
  import { caps } from "./stores/caps.svelte";
  import { onMount, onDestroy } from "svelte";

  let statusInterval: NodeJS.Timeout;

  onMount(() => {
    // Check status immediately when component mounts
    if (account.account) {
      planetelo.update_status();
    }
    
    // Set up interval to check status every 3 seconds
    statusInterval = setInterval(() => {
      if (account.account) {
        planetelo.update_status();
      }
    }, 15000);
  });

  onDestroy(() => {
    // Clean up interval when component is destroyed
    if (statusInterval) {
      clearInterval(statusInterval);
    }
  });
</script>

<div class="matchmaking-container">
  <!-- Planetelo Matchmaking -->
  <div class="game-section">
    <h3>Planetelo Matchmaking</h3>
    {#if account.account && !planetelo.planetelo_game_id}
      {#if planetelo.queue_status == 0 || planetelo.queue_status == null}
        <button onclick={planetelo.handleQueue}>Queue</button>
      {:else if planetelo.queue_status == 1}
        {#if planetelo.queue_length && planetelo.queue_length >= 2}
          <button class="match-found" onclick={planetelo.handleMatchmake}>Match Found</button>
        {:else}
          <button disabled>In Queue</button>
        {/if}
      {/if}
    {:else if account.account && planetelo.planetelo_game_id}
      {#if caps.game_state?.game.over}
        <button onclick={planetelo.handleSettle}>Settle</button>
      {:else if planetelo.current_game_id == planetelo.planetelo_game_id}
        <button disabled>Active</button>
      {:else}
        <button onclick={() => {
          planetelo.set_current_game_id(planetelo.planetelo_game_id!);
          caps.get_game(planetelo.planetelo_game_id!);
        }}>Switch</button>
      {/if}
    {:else}
      <p>Connect wallet to queue</p>
    {/if}
  </div>

  <!-- Agent Game -->
  <div class="game-section">
    <h3>Agent Game</h3>
    {#if account.account && !planetelo.agent_game_id}
      <button onclick={planetelo.play_agent}>Play Agent</button>
    {:else if account.account && planetelo.agent_game_id}
      {#if caps.game_state?.game.over && planetelo.current_game_id == planetelo.agent_game_id}
        <button onclick={planetelo.settle_agent_game}>Settle</button>
      {:else if planetelo.current_game_id == planetelo.agent_game_id}
        <button disabled>Active</button>
      {:else}
        <button onclick={() => {
          planetelo.set_current_game_id(planetelo.agent_game_id!);
          caps.get_game(planetelo.agent_game_id!);
        }}>Switch</button>
      {/if}
    {:else}
      <p>Connect wallet to play</p>
    {/if}
  </div>
</div>

<style>
  .matchmaking-container {
    display: flex;
    gap: 1rem;
    margin: 1rem 0;
  }

  .game-section {
    border: 1px solid #ccc;
    padding: 1rem;
    border-radius: 8px;
    flex: 1;
  }

  .game-section h3 {
    margin: 0 0 1rem 0;
    font-size: 1.1rem;
  }

  button {
    padding: 0.5rem 1rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    background: #f0f0f0;
    cursor: pointer;
    font-size: 1rem;
  }

  button:hover:not(:disabled) {
    background: #e0e0e0;
  }

  button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .match-found {
    background: #10b981 !important;
    color: white;
    border-color: #059669;
  }

  .match-found:hover {
    background: #059669 !important;
  }

  @media (max-width: 768px) {
    .matchmaking-container {
      flex-direction: column;
    }
  }
</style>