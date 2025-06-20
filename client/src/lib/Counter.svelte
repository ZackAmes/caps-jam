<script lang="ts">
  import {account} from "./account.svelte";

  $effect(() => {
    console.log(account.account);
  });
</script>

{#if !account.p1Account}
  <button onclick={account.connectP1}>Connect</button>
{:else}
  <button onclick={account.disconnectP1}>Disconnect</button>
  <p>P1 Connected as {account.p1Username}</p>
{/if}
{#if !account.p2Account}
  <button onclick={account.connectP2}>Connect</button>
{:else}
  <button onclick={account.disconnectP2}>Disconnect</button>
  <p>P2 Connected as {account.p2Username}</p>
{/if}
