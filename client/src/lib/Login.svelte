<script lang="ts">
  import {account} from "./account.svelte";
  import { planetelo } from "./planetelo.svelte";
  import Game from "./Game.svelte";

  $effect(() => {
    console.log(planetelo.queue_status)
    planetelo.update_status();
  });
</script>

{#if !account.account}
  <button onclick={account.connect}>Connect</button>
{:else}
  <button onclick={account.disconnect}>Disconnect</button>
  <p>Connected as {account.username}</p>
{/if}
{#if account.account && !planetelo.queue_status}
  <button onclick={() => planetelo.update_status()}>Update Status</button>
{/if}
{#if planetelo.queue_status == 0}
  <button onclick={planetelo.handleQueue}>Queue</button>
{:else if planetelo.queue_status == 1}
  <button onclick={planetelo.handleMatchmake}>Matchmake</button>
{:else if planetelo.queue_status == 2}
  <Game />
{/if}