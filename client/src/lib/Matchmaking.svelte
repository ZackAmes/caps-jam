<script lang="ts">
  import { planetelo } from "./stores/planetelo.svelte";
</script>

{#if planetelo.queue_status == 0}
  <button onclick={planetelo.handleQueue}>Queue</button>
{:else if planetelo.queue_status == 1}
  <button onclick={planetelo.handleMatchmake}>Matchmake</button>
{/if}