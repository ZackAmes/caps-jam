<script lang="ts">
    import { Canvas } from '@threlte/core'
    import Game from '../Game.svelte'
    import CapData from '../ui/cap_data.svelte'
    import MoveData from '../ui/move_data.svelte'
    import Popup from '../ui/popup.svelte'
    import { caps } from '../stores/caps.svelte'
    import { planetelo } from '../stores/planetelo.svelte'
    import { push } from 'svelte-spa-router'
    
    const { params }: { params: { game_id: string } } = $props()
    
    const game_id = parseInt(params.game_id)

    // Load the game when component mounts or game_id changes
    $effect(() => {
        if (game_id && !isNaN(game_id)) {
            caps.get_game(game_id)
        }
    })
    
    // Navigation functions - these now use URL routing instead of direct state updates 🐙
    const handleSwitchToAgentGame = () => {
        if (planetelo.agent_game_id) {
            push(`/game/${planetelo.agent_game_id}`)
        }
    }
    
    const handleSwitchToPlaneteloGame = () => {
        if (planetelo.planetelo_game_id) {
            push(`/game/${planetelo.planetelo_game_id}`)
        }
    }
    
    const handleBackHome = () => {
        push('/')
    }
</script>

<div class="game-header">
    <button class="back-button" onclick={handleBackHome}>← Back to Menu</button>
    <h2>Game {game_id}</h2>
    <div class="game-controls">
        {#if planetelo.agent_game_id && planetelo.planetelo_game_id}
            {#if game_id === planetelo.agent_game_id}
                <button onclick={handleSwitchToPlaneteloGame}>Switch to Planetelo Game</button>
            {:else if game_id === planetelo.planetelo_game_id}
                <button onclick={handleSwitchToAgentGame}>Switch to Agent Game</button>
            {/if}
        {/if}
    </div>
</div>

{#if caps.selected_cap}
    <CapData capType="selected" />
{/if}
{#if caps.inspected_cap}
    <CapData capType="inspected" />
{/if}
{#if caps.popup_state.visible}
    <Popup />
{/if}

{#if caps.game_state && !caps.game_state.game.over}
    <MoveData />
    <div class="game-board-container">
        <Canvas>
            <Game />
        </Canvas>
    </div>
    <div class="action-buttons">
        <button onclick={() => caps.reset_move()}>Reset Move</button>
        <button onclick={() => caps.take_turn()}>Take Turn</button>
    </div>
{:else if caps.game_state?.game.over}
    <div class="game-over">
        <h3>Game Over!</h3>
        {#if game_id === planetelo.planetelo_game_id}
            <div class="card">
                <button onclick={() => planetelo.handleSettle()}>Settle Match</button>
            </div>
        {:else if game_id === planetelo.agent_game_id}
            <div class="card">
                <button onclick={() => planetelo.settle_agent_game()}>Settle Game</button>
            </div>
        {/if}
    </div>
{:else}
    <div class="loading">
        <p>Loading game {game_id}...</p>
    </div>
{/if}

<style>
    .game-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 1rem;
        padding: 1rem;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 8px;
    }
    
    .back-button {
        padding: 0.5rem 1rem;
        background: rgba(255, 255, 255, 0.1);
        border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 4px;
        color: white;
        cursor: pointer;
        transition: background 0.2s;
    }
    
    .back-button:hover {
        background: rgba(255, 255, 255, 0.2);
    }
    
    .game-controls {
        display: flex;
        gap: 0.5rem;
    }
    
    .action-buttons {
        display: flex;
        gap: 1rem;
        justify-content: center;
        margin-top: 1rem;
    }
    
    .action-buttons button {
        padding: 0.75rem 1.5rem;
        font-size: 1rem;
        border-radius: 4px;
        cursor: pointer;
    }
    
    .game-over {
        text-align: center;
        padding: 2rem;
    }
    
    .loading {
        text-align: center;
        padding: 2rem;
    }
    
    /* Mobile responsive layout adjustments */
    @media (max-width: 720px) {
        .game-header {
            flex-direction: column;
            gap: 1rem;
        }
        
        .action-buttons {
            flex-direction: column;
            align-items: center;
        }
        
        .action-buttons button {
            width: 100%;
            max-width: 300px;
        }
    }
</style>
