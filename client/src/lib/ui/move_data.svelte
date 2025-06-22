<script lang="ts">
	import type { Action, Moved } from '../dojo/models.gen.ts';
    import { caps } from '../stores/caps.svelte';

    let isDragging = false;
    let dragOffset = { x: 0, y: 0 };
    let position = { x: 260, y: 20 }; // Position it next to the cap_data overlay

    function handleMouseDown(e: MouseEvent) {
        isDragging = true;
        dragOffset.x = e.clientX - position.x;
        dragOffset.y = e.clientY - position.y;
    }

    function handleMouseMove(e: MouseEvent) {
        if (isDragging) {
            position.x = e.clientX - dragOffset.x;
            position.y = e.clientY - dragOffset.y;
        }
    }

    function handleMouseUp() {
        isDragging = false;
    }

    // Assuming these exist in the caps store - adjust as neede
</script>

<svelte:window on:mousemove={handleMouseMove} on:mouseup={handleMouseUp} />

{#if caps.selected_cap}
    <div 
        class="move-overlay" 
        style="left: {position.x}px; top: {position.y}px;"
        on:mousedown={handleMouseDown}
        role="button"
        tabindex="0"
    >
        <div class="move-box">
            <div class="header">
                <strong>Move Data</strong>
            </div>
            
            <div class="content">
                <div class="energy">
                    Energy: {caps.energy}/{caps.max_energy}
                </div>
                
                <div class="energy-bar">
                    <div class="energy-fill" style="width: {(caps.energy / caps.max_energy) * 100}%"></div>
                </div>
                
                <div class="moves-section">
                    <div class="section-title">Current Moves:</div>
                    {#if caps.current_move}
                        {#each caps.current_move as move, index}
                            <div class="move-item">
                                <span class="move-number">{index + 1}.</span>
                                <span class="move-type">
                                    {#if move.action_type?.activeVariant() === 'Move'}
                                        {@const dir = move.action_type.unwrap()}
                                        {@const new_x = dir.x == 0 ? Number(caps.selected_cap.position.x) + Number(dir.y) : dir.x == 1 ? Number(caps.selected_cap.position.x) - Number(dir.y) : Number(caps.selected_cap.position.x)}
                                        {@const new_y = dir.y == 2 ? Number(caps.selected_cap.position.y) + Number(dir.x) : dir.y == 3 ? Number(caps.selected_cap.position.y) - Number(dir.x) : Number(caps.selected_cap.position.y)}
                                        Move to ({new_x}, {new_y})
                                    {:else if move.action_type?.activeVariant() === 'Attack'}
                                        Attack ({move.action_type.unwrap().x}, {move.action_type.unwrap().y})
                                    {/if}
                                </span>
                            </div>
                        {/each}
                    {:else}
                        <div class="no-moves">No moves planned</div>
                    {/if}
                </div>
                
                <div class="move-stats">
                    <div>Total Moves: {caps.current_move.length}</div>
                    <div>Energy Used: {caps.max_energy - caps.energy}</div>
                    <div>Remaining: {caps.energy}</div>
                </div>
            </div>
        </div>
    </div>
{/if}

<style>
    .move-overlay {
        position: fixed;
        z-index: 1000;
        cursor: move;
        user-select: none;
    }

    .move-box {
        background: white;
        border: 2px solid #333;
        border-radius: 6px;
        padding: 12px;
        width: 220px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        font-family: Arial, sans-serif;
        font-size: 14px;
    }

    /* Mobile responsive move data */
    @media (max-width: 768px) {
        .move-overlay {
            /* Position at bottom of screen on mobile */
            left: 0.5rem !important;
            right: 0.5rem !important;
            bottom: 0.5rem !important;
            top: auto !important;
            width: auto !important;
            cursor: default; /* Disable dragging on mobile */
        }

        .move-box {
            width: 100%;
            max-width: none;
            padding: 16px;
            font-size: 16px;
            border-radius: 8px;
            max-height: 40vh;
            overflow-y: auto;
        }
    }

    .header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 8px;
        padding-bottom: 6px;
        border-bottom: 1px solid #ddd;
    }

    .header strong {
        color: #333;
        font-size: 16px;
    }

    @media (max-width: 768px) {
        .header strong {
            font-size: 18px;
        }
    }

    .content {
        color: #444;
    }

    .energy {
        margin-bottom: 4px;
        font-weight: bold;
        color: #2980b9;
    }

    @media (max-width: 768px) {
        .energy {
            font-size: 18px;
            margin-bottom: 8px;
        }
    }

    .energy-bar {
        width: 100%;
        height: 8px;
        background: #ecf0f1;
        border-radius: 4px;
        margin-bottom: 12px;
        overflow: hidden;
    }

    @media (max-width: 768px) {
        .energy-bar {
            height: 12px;
            border-radius: 6px;
            margin-bottom: 16px;
        }
    }

    .energy-fill {
        height: 100%;
        background: linear-gradient(90deg, #3498db, #2980b9);
        transition: width 0.3s ease;
    }

    .moves-section {
        margin-bottom: 8px;
    }

    @media (max-width: 768px) {
        .moves-section {
            margin-bottom: 12px;
        }
    }

    .section-title {
        font-weight: bold;
        margin-bottom: 4px;
        color: #333;
    }

    @media (max-width: 768px) {
        .section-title {
            font-size: 16px;
            margin-bottom: 8px;
        }
    }

    .move-item {
        display: flex;
        align-items: center;
        margin: 2px 0;
        font-size: 13px;
    }

    @media (max-width: 768px) {
        .move-item {
            margin: 6px 0;
            font-size: 16px;
        }
    }

    .move-number {
        color: #666;
        margin-right: 6px;
        font-weight: bold;
    }

    .move-type {
        color: #555;
    }

    .no-moves {
        color: #999;
        font-style: italic;
        font-size: 13px;
    }

    @media (max-width: 768px) {
        .no-moves {
            font-size: 16px;
        }
    }

    .move-stats {
        border-top: 1px solid #ddd;
        padding-top: 8px;
        margin-top: 8px;
    }

    @media (max-width: 768px) {
        .move-stats {
            padding-top: 12px;
            margin-top: 12px;
        }
    }

    .move-stats div {
        margin: 4px 0;
        color: #555;
        font-size: 13px;
    }

    @media (max-width: 768px) {
        .move-stats div {
            margin: 6px 0;
            font-size: 16px;
        }
    }
</style>
