<script lang="ts">
  import Router from 'svelte-spa-router'
  import { routes } from './lib/router'
  
  // Import stores to ensure they're initialized - let the tentacles take the wheel! 🐙
  import { account } from './lib/stores/account.svelte'
  import { planetelo } from './lib/stores/planetelo.svelte'
  import { caps } from './lib/stores/caps.svelte'
</script>

<main>
  <Router {routes} />
</main>

<style>
  main {
    padding: 1rem;
    max-width: 100vw;
    margin: 0 auto;
  }
</style>
