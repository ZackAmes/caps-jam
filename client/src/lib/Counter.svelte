<script lang="ts">
  import {account} from "./account.svelte";

  $effect(() => {
    console.log(account.account);
  });
</script>

{#if !account.account}
  <button onclick={account.connect}>Connect</button>
{:else}
  <button onclick={account.disconnect}>Disconnect</button>
  <p>Connected as {account.username}</p>
{/if}
