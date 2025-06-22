<script lang="ts">
    import { caps } from '../stores/caps.svelte';
    
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
    
    function handleActionClick(action: {type: 'move' | 'attack' | 'ability', label: string}) {
        if (popup.position) {
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
                <div class="action-buttons">
                    {#each popup.available_actions as action}
                        <button 
                            class="action-button action-{action.type}"
                            onclick={() => handleActionClick(action)}
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
        width: 120px;
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
        font-size: 12px;
        font-weight: 500;
        transition: all 0.2s;
    }

    .action-button:hover {
        transform: translateY(-1px);
    }

    .action-move {
        background-color: #3b82f6;
        color: white;
    }

    .action-move:hover {
        background-color: #2563eb;
    }

    .action-attack {
        background-color: #ef4444;
        color: white;
    }

    .action-attack:hover {
        background-color: #dc2626;
    }

    .action-ability {
        background-color: #8b5cf6;
        color: white;
    }

    .action-ability:hover {
        background-color: #7c3aed;
    }
</style>
