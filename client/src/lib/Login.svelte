<script lang="ts">
  import {account} from "./stores/account.svelte";
  import { planetelo } from "./stores/planetelo.svelte";
  import Game from "./Game.svelte";
  import { caps } from "./stores/caps.svelte";
  
</script>

{#if !account.account}
  <button onclick={account.connect}>Connect</button>
{:else}
  <button onclick={account.disconnect}>Disconnect</button>
  <p>Connected as {account.username}</p>
{/if}
{#if account.account}
  <button onclick={() => planetelo.update_status()}>Update Status</button>
{/if}