<script lang="ts">
	import type { Action, Moved } from '../dojo/models.gen.ts';
    import { caps } from '../stores/caps.svelte';

    let isDragging = false;
    let dragOffset = { x: 0, y: 0 };
    let position = $state({ x: 260, y: 20 }); 

    function handleMouseDown(e: MouseEvent) {
        if (window.innerWidth <= 768) return;
        isDragging = true;
        dragOffset.x = e.clientX - position.x;
        dragOffset.y = e.clientY - position.y;
    }

    function handleMouseMove(e: MouseEvent) {
        if (window.innerWidth <= 768) return;
        if (isDragging) {
            position.x = e.clientX - dragOffset.x;
            position.y = e.clientY - dragOffset.y;
        }
    }

    function handleMouseUp() {
        if (window.innerWidth <= 768) return;
        isDragging = false;
    }
</script>

<svelte:window on:mousemove={handleMouseMove} on:mouseup={handleMouseUp} />

{#if caps.selected_cap}
    <div 
        class="move-data-container"
        class:desktop-popup={typeof window !== 'undefined' && window.innerWidth > 768}
        class:mobile-static={typeof window !== 'undefined' && window.innerWidth <= 768}
        style={typeof window !== 'undefined' && window.innerWidth > 768 ? `left: ${position.x}px; top: ${position.y}px;` : ''}
        on:mousedown={handleMouseDown}
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
                    {#if caps.current_move.length > 0}
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
    .move-data-container.desktop-popup {
        position: fixed;
        z-index: 1000;
        cursor: move;
        user-select: none;
        width: 240px;
    }

    .move-data-container.mobile-static {
        width: 100%;
        box-sizing: border-box;
        margin: 1rem 0;
    }

    .move-box {
        background: white;
        border: 2px solid #333;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        font-family: Arial, sans-serif;
        font-size: 14px;
        padding: 12px;
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

    .content {
        color: #444;
    }

    .energy {
        margin-bottom: 4px;
        font-weight: bold;
        color: #2980b9;
    }

    .energy-bar {
        width: 100%;
        height: 8px;
        background: #ecf0f1;
        border-radius: 4px;
        margin-bottom: 12px;
        overflow: hidden;
    }

    .energy-fill {
        height: 100%;
        background: linear-gradient(90deg, #3498db, #2980b9);
        transition: width 0.3s ease;
    }

    .moves-section {
        margin-bottom: 8px;
    }

    .section-title {
        font-weight: bold;
        margin-bottom: 4px;
        color: #333;
    }

    .move-item {
        display: flex;
        align-items: center;
        margin: 2px 0;
        font-size: 13px;
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

    .move-stats {
        border-top: 1px solid #ddd;
        padding-top: 8px;
        margin-top: 8px;
    }

    .move-stats div {
        margin: 4px 0;
        color: #555;
        font-size: 13px;
    }

    @media (max-width: 768px) {
        .move-box {
            padding: 16px;
            font-size: 1rem;
        }

        .move-stats div, .move-item, .no-moves {
            font-size: 1rem;
        }
    }
</style>
