<script lang="ts">
    import Login from '../Login.svelte'
    import Matchmaking from '../Matchmaking.svelte'
    import CapData from '../ui/cap_data.svelte'
    import Popup from '../ui/popup.svelte'
    import TeamSelector from '../ui/TeamSelector.svelte'
    import { account } from '../stores/account.svelte'
    import { caps } from '../stores/caps.svelte'
    import { planetelo } from '../stores/planetelo.svelte'
    import { push } from 'svelte-spa-router'

    // Navigate to game when a game is ready
    $effect(() => {
        // Navigate to planetelo game if ready
        if (planetelo.queue_status === 2 && planetelo.planetelo_game_id) {
            push(`/game/${planetelo.planetelo_game_id}`)
        }
        // Navigate to agent game if ready  
        else if (planetelo.agent_game_id && caps.game_state) {
            push(`/game/${planetelo.agent_game_id}`)
        }
    })
</script>

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

<!-- Quick game access buttons when games are available but not currently viewing -->
{#if planetelo.agent_game_id && !caps.game_state}
<div class="card">
    <button onclick={() => push(`/game/${planetelo.agent_game_id}`)}>
        View Agent Game
    </button>
</div>
{/if}

{#if planetelo.queue_status === 2 && !caps.game_state && planetelo.planetelo_game_id}
<div class="card">
    <button onclick={() => push(`/game/${planetelo.planetelo_game_id}`)}>
        View Planetelo Game  
    </button>
</div>
{/if}

<style>
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
