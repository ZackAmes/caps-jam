<script lang="ts">
  import {account} from "./stores/account.svelte";
  import { planetelo } from "./stores/planetelo.svelte";
  import Game from "./Game.svelte";
  import { caps } from "./stores/caps.svelte";
  import Profile from "./ui/Profile.svelte";
  
</script>

{#if !account.account}
  <button onclick={account.connect}>Connect</button>
{:else}
  <Profile />
{/if}
{#if account.account && planetelo.queue_status == 2 && planetelo.current_game_id}
  <button onclick={() => caps.get_game(planetelo.current_game_id!)}>Refresh Game</button>
{/if}