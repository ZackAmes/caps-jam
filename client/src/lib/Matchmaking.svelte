<script lang="ts">
  import { planetelo } from "./stores/planetelo.svelte";
  import { account } from "./stores/account.svelte";
</script>

{#if planetelo.queue_status == 0}
  <button onclick={planetelo.handleQueue}>Queue</button>
{:else if planetelo.queue_status == 1}
  <button onclick={planetelo.handleMatchmake}>Matchmake</button>
{/if}
{#if account.account && !planetelo.agent_game_id}
  <button onclick={planetelo.play_agent}>Play Agent</button>
{:else if account.account && planetelo.agent_game_id}
  <button onclick={planetelo.settle_agent_game}>Settle Agent Game</button>
{/if}
{#if planetelo.agent_game_id && planetelo.current_game_id}
  <button onclick={planetelo.switch_current_game}>Switch Between Games</button>
{/if}