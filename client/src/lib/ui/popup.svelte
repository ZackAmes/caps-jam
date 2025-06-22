<script lang="ts">
    import { caps } from '../stores/caps.svelte';
    import type { Cap } from '../dojo/models.gen';
    let popup = caps.popup_state;
    let isDragging = false;
    let dragOffset = { x: 0, y: 0 };
    
    $effect(() => {
        console.log(popup.render_position)
    })
    // Calculate position based on grid coordinates (assuming ~50px per cell)
    let render_position = $derived(popup.render_position ? {
        x: popup.render_position.x, // offset from board edge
        y: popup.render_position.y - 150
    } : { x: 300, y: 100 });
    let get_action_details = (cap: Cap) => {
        if (!cap || !caps.cap_types) return [];
        
        const capType = caps.cap_types.find(ct => ct.id == cap.cap_type);
        if (!capType) return [];
        
        return popup.available_actions.map(action => {
            let cost = 0;
            let canAfford = true;
            
            switch (action.type) {
                case 'move':
                    cost = Number(capType.move_cost);
                    break;
                case 'attack':
                    cost = Number(capType.attack_cost);
                    break;
                case 'ability':
                    cost = Number(capType.ability_cost);
                    break;
            }
            
            canAfford = caps.energy >= cost;
            
            return {
                ...action,
                cost,
                canAfford,
                label: `${action.label} (${cost})`
            };
        })
    }
    // Get the cost and availability for each action
    let actionDetails = $derived(get_action_details(caps.selected_cap!));
    
    function handleActionClick(action: {type: 'move' | 'attack' | 'ability', label: string, cost: number, canAfford: boolean}) {
        if (popup.position && action.canAfford) {
            caps.execute_action(action.type, popup.position);
        }
    }
    
    function handleMouseDown(e: MouseEvent) {
        isDragging = true;
        dragOffset.x = e.clientX - render_position.x;
        dragOffset.y = e.clientY - render_position.y;
    }

    function handleMouseMove(e: MouseEvent) {
        if (isDragging) {
            render_position.x = e.clientX - dragOffset.x;
            render_position.y = e.clientY - dragOffset.y;
        }
    }

    function handleMouseUp() {
        isDragging = false;
    }
</script>

<svelte:window on:mousemove={handleMouseMove} on:mouseup={handleMouseUp} />

{#if popup.visible && popup.render_position}
    <div 
        class="action-overlay" 
        style="left: {render_position.x}px; top: {render_position.y}px;"
        onmousedown={handleMouseDown}
        role="button"
        tabindex="0"
    >
        <div class="action-box">
            <div class="header">
                <strong>Actions</strong>
                <button class="close-button" onclick={() => caps.close_popup()}>×</button>
            </div>
            
            <div class="content">
                <div class="energy-display">
                    Energy: {caps.energy}/{caps.max_energy}
                </div>
                
                <div class="action-buttons">
                    {#each actionDetails as action}
                        <button 
                            class="action-button action-{action.type}"
                            class:disabled={!action.canAfford}
                            onclick={() => handleActionClick(action)}
                            disabled={!action.canAfford}
                            title={action.canAfford ? '' : `Need ${action.cost} energy (have ${caps.energy})`}
                        >
                            {action.label}
                        </button>
                    {/each}
                </div>
            </div>
        </div>
    </div>
{/if}

<style>
    .action-overlay {
        position: fixed;
        z-index: 1000;
        cursor: move;
        user-select: none;
    }

    .action-box {
        background: white;
        border: 2px solid #333;
        border-radius: 4px;
        padding: 8px;
        width: 140px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        font-family: Arial, sans-serif;
        font-size: 12px;
    }

    .header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 6px;
        padding-bottom: 4px;
        border-bottom: 1px solid #ddd;
    }

    .header strong {
        color: #333;
        font-size: 14px;
    }

    .close-button {
        background: none;
        border: none;
        font-size: 16px;
        cursor: pointer;
        color: #666;
        padding: 0;
        width: 16px;
        height: 16px;
    }

    .close-button:hover {
        color: #333;
    }

    .content {
        color: #444;
    }

    .energy-display {
        background: #f0f9ff;
        border: 1px solid #0ea5e9;
        border-radius: 3px;
        padding: 4px 6px;
        margin-bottom: 6px;
        font-size: 11px;
        font-weight: 500;
        color: #0369a1;
        text-align: center;
    }

    .action-buttons {
        display: flex;
        flex-direction: column;
        gap: 4px;
    }

    .action-button {
        padding: 6px 8px;
        border: none;
        border-radius: 3px;
        cursor: pointer;
        font-size: 11px;
        font-weight: 500;
        transition: all 0.2s;
        position: relative;
    }

    .action-button:hover:not(.disabled) {
        transform: translateY(-1px);
    }

    .action-button.disabled {
        opacity: 0.5;
        cursor: not-allowed;
        background-color: #9ca3af !important;
        color: #6b7280 !important;
    }

    .action-button.disabled:hover {
        transform: none;
    }

    .action-move {
        background-color: #3b82f6;
        color: white;
    }

    .action-move:hover:not(.disabled) {
        background-color: #2563eb;
    }

    .action-attack {
        background-color: #ef4444;
        color: white;
    }

    .action-attack:hover:not(.disabled) {
        background-color: #dc2626;
    }

    .action-ability {
        background-color: #8b5cf6;
        color: white;
    }

    .action-ability:hover:not(.disabled) {
        background-color: #7c3aed;
    }
</style>
