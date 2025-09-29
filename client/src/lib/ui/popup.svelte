<script lang="ts">
    import { caps } from '../stores/caps.svelte';
    import type { Cap } from '../dojo/models.gen';
    
    let popup = caps.popup_state;
    let isDragging = false;
    let isResizing = false;
    let dragOffset = { x: 0, y: 0 };
    
    // Size state for resizing
    let size = $state({
        width: 300,
        height: 250
    });

    // Position state, nullable to prevent rendering before it's set
    let position = $state<{ x: number, y: number } | null>(null);
    
    $effect(() => {
        if (popup.render_position) {
            const popupHeight = size.height;
            const popupWidth = size.width;
            
            let newX = popup.render_position.x + 20;
            let newY = popup.render_position.y - (popupHeight + 20);

            // Flip to below the cursor if there's no space above
            if (newY < 0) {
                newY = popup.render_position.y + 20;
            }

            // Clamp to viewport bounds
            if (newX < 10) newX = 10;
            if (newX + popupWidth > window.innerWidth) {
                newX = window.innerWidth - popupWidth - 10;
            }
            if (newY + popupHeight > window.innerHeight) {
                newY = window.innerHeight - popupHeight - 10;
            }

            position = { x: newX, y: newY };
        } else {
            // Ensure position is null if render_position is not available
            position = null;
        }
    });

    function handleMouseDown(e: MouseEvent) {
        if (!position) return;
        if ((e.target as HTMLElement).classList.contains('resize-handle')) {
            isResizing = true;
        } else {
            isDragging = true;
            dragOffset.x = e.clientX - position.x;
            dragOffset.y = e.clientY - position.y;
        }
        e.preventDefault();
    }

    function handleMouseMove(e: MouseEvent) {
        if (!position) return;
        if (isDragging) {
            position.x = e.clientX - dragOffset.x;
            position.y = e.clientY - dragOffset.y;
        } else if (isResizing) {
            size.width = Math.max(180, e.clientX - position.x);
            size.height = Math.max(120, e.clientY - position.y);
        }
    }

    function handleMouseUp() {
        isDragging = false;
        isResizing = false;
    }

    function handleTouchStart(e: TouchEvent) {
        if (!position) return;
        const touch = e.touches[0];
        if ((e.target as HTMLElement).classList.contains('resize-handle')) {
            isResizing = true;
        } else {
            isDragging = true;
            dragOffset.x = touch.clientX - position.x;
            dragOffset.y = touch.clientY - position.y;
        }
        e.preventDefault();
    }

    function handleTouchMove(e: TouchEvent) {
        if (!position) return;
        const touch = e.touches[0];
        if (isDragging) {
            position.x = touch.clientX - dragOffset.x;
            position.y = touch.clientY - dragOffset.y;
        } else if (isResizing) {
            size.width = Math.max(160, touch.clientX - position.x);
            size.height = Math.max(100, touch.clientY - position.y);
        }
        e.preventDefault();
    }

    function handleTouchEnd() {
        isDragging = false;
        isResizing = false;
    }

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
                case 'play':
                    // Tentacles deploy from the depths! 🐙
                    cost = Number(capType.play_cost);
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
    
    // Type guard to check for executable actions - tentacles support all deployment types! 🐙
    function isExecutableAction(action: any): action is {type: 'move' | 'attack' | 'ability' | 'play', label: string, cost: number, canAfford: boolean} {
        return action.type === 'move' || action.type === 'attack' || action.type === 'ability' || action.type === 'play';
    }

    function handleActionClick(action: {type: 'move' | 'attack' | 'ability' | 'play', label: string, cost: number, canAfford: boolean}) {
        console.log('=== handleActionClick in popup ===');
        console.log('Action:', action);
        console.log('Popup position:', popup.position);
        
        if (popup.position && action.canAfford) {
            console.log('Calling caps.execute_action with:', action.type, popup.position);
            caps.execute_action(action.type, popup.position);
            handleClose(); // Close popup after action
        } else {
            console.log('Cannot execute - position:', popup.position, 'canAfford:', action.canAfford);
        }
    }
    
    function handleClose() {
        caps.close_popup();
    }

    // New handler to fix type error
    function onActionButtonClick(action: (typeof actionDetails)[0]) {
        if (isExecutableAction(action)) {
            handleActionClick(action);
        } else {
            // Handle other action types like 'deselect'
            handleClose();
        }
    }
</script>

<svelte:window 
    on:mousemove={handleMouseMove} 
    on:mouseup={handleMouseUp}
    on:touchmove={handleTouchMove}
    on:touchend={handleTouchEnd}
/>

{#if popup.visible && popup.position && position}
    <div 
        class="action-popup"
        class:mobile={typeof window !== 'undefined' && window.innerWidth <= 768}
        style="left: {position.x}px; top: {position.y}px; width: {size.width}px; height: {size.height}px;"
        onmousedown={handleMouseDown}
        ontouchstart={handleTouchStart}
        role="dialog"
        aria-label="Action Selection"
    >
        <div class="popup-header">
            <span class="popup-title">Select Action</span>
            <button class="close-button" onclick={handleClose}>×</button>
        </div>
        
        <div class="popup-content">
            <div class="energy-display">
                Energy: {caps.energy}/{caps.max_energy}
            </div>
            
            <div class="action-buttons">
                {#each actionDetails as action}
                    <button 
                        class="action-button action-{action.type}"
                        class:disabled={!action.canAfford}
                        onclick={() => onActionButtonClick(action)}
                        disabled={!action.canAfford}
                    >
                        {action.label}
                    </button>
                {/each}
            </div>
        </div>
        
        <!-- Resize handle -->
        <div class="resize-handle"></div>
    </div>
{/if}

<style>
    .action-popup {
        position: fixed;
        z-index: 1000;
        background: white;
        border: 2px solid #333;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        min-width: 180px;
        min-height: 120px;
        max-width: 90vw;
        max-height: 90vh;
        overflow: hidden;
        cursor: move;
        user-select: none;
        font-size: 12px;
    }

    .action-popup.mobile {
        font-size: 16px;
        min-width: 160px;
        min-height: 100px;
        border-radius: 12px;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
    }

    .action-popup:active {
        cursor: grabbing;
    }

    .popup-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 12px;
        background: #f5f5f5;
        border-bottom: 1px solid #ddd;
        cursor: move;
        flex-shrink: 0;
    }

    .action-popup.mobile .popup-header {
        padding: 12px 16px;
        touch-action: none;
    }

    .popup-title {
        color: #333;
        font-size: 14px;
        font-weight: bold;
        margin: 0;
    }

    .action-popup.mobile .popup-title {
        font-size: 18px;
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
        margin-left: 8px;
    }

    .action-popup.mobile .close-button {
        font-size: 24px;
        width: 32px;
        height: 32px;
        padding: 4px;
        min-height: 44px;
        min-width: 44px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .close-button:hover {
        color: #333;
    }

    .popup-content {
        color: #444;
        padding: 8px 12px;
        overflow-y: auto;
        flex: 1;
    }

    .action-popup.mobile .popup-content {
        padding: 12px 16px;
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

    .action-popup.mobile .energy-display {
        padding: 8px 12px;
        font-size: 16px;
        border-radius: 6px;
        margin-bottom: 12px;
    }

    .action-buttons {
        display: flex;
        flex-direction: column;
        gap: 4px;
    }

    .action-popup.mobile .action-buttons {
        gap: 8px;
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

    .action-popup.mobile .action-button {
        padding: 12px 16px;
        font-size: 16px;
        border-radius: 6px;
        min-height: 48px;
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

    .resize-handle {
        position: absolute;
        bottom: 0;
        right: 0;
        width: 16px;
        height: 16px;
        background: linear-gradient(135deg, transparent 50%, #999 50%);
        cursor: se-resize;
        border-top-left-radius: 4px;
    }

    .action-popup.mobile .resize-handle {
        width: 24px;
        height: 24px;
        background: linear-gradient(135deg, transparent 50%, #666 50%);
    }

    .resize-handle:hover {
        background: linear-gradient(135deg, transparent 50%, #666 50%);
    }

    /* Touch optimization */
    @media (pointer: coarse) {
        .action-popup {
            touch-action: none;
        }
        
        .popup-header {
            min-height: 44px;
        }
        
        .close-button {
            min-height: 44px;
            min-width: 44px;
        }
    }

    /* Mobile responsive positioning override */
    @media (max-width: 768px) {
        .action-popup.mobile {
            position: fixed !important;
            left: 50% !important;
            top: 50% !important;
            transform: translate(-50%, -50%) !important;
            cursor: default;
        }
    }
</style>
