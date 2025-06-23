<script lang="ts">
	import type { Cap, CapType } from '../dojo/models.gen.ts';
    import { caps } from '../stores/caps.svelte';

    // Props to specify which cap to display
    let { capType = 'selected' }: { capType?: 'selected' | 'inspected' } = $props();

    let isDragging = false;
    let isResizing = false;
    let dragOffset = { x: 0, y: 0 };
    
    // Initialize position based on click coordinates, then allow dragging
    let position = $state({
        x: capType === 'selected' ? 20 : 260, 
        y: capType === 'selected' ? 20 : 20
    });

    // Size state for resizing
    let size = $state({
        width: 240,
        height: 200
    });

    // Update position when render position changes (new click)
    $effect(() => {
        if (capType === 'selected' && caps.selected_cap_render_position) {
            position.x = caps.selected_cap_render_position.x;
            position.y = caps.selected_cap_render_position.y - 150;
        } else if (capType === 'inspected' && caps.inspected_cap_render_position) {
            position.x = caps.inspected_cap_render_position.x;
            position.y = caps.inspected_cap_render_position.y - 150;
        }
    });

    function handleMouseDown(e: MouseEvent) {
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
        if (isDragging) {
            position.x = e.clientX - dragOffset.x;
            position.y = e.clientY - dragOffset.y;
        } else if (isResizing) {
            const rect = e.currentTarget as HTMLElement;
            size.width = Math.max(200, e.clientX - position.x);
            size.height = Math.max(150, e.clientY - position.y);
        }
    }

    function handleMouseUp() {
        isDragging = false;
        isResizing = false;
    }

    function handleTouchStart(e: TouchEvent) {
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
        const touch = e.touches[0];
        if (isDragging) {
            position.x = touch.clientX - dragOffset.x;
            position.y = touch.clientY - dragOffset.y;
        } else if (isResizing) {
            size.width = Math.max(180, touch.clientX - position.x);
            size.height = Math.max(120, touch.clientY - position.y);
        }
        e.preventDefault();
    }

    function handleTouchEnd() {
        isDragging = false;
        isResizing = false;
    }

    // Determine which cap to display based on capType prop
    let display_cap = $derived(capType === 'inspected' ? caps.inspected_cap : caps.selected_cap);
    let is_opponent = $derived(capType === 'inspected' && caps.inspected_cap && caps.inspected_cap.owner !== caps.selected_cap?.owner);

    let effects = $derived(caps.game_state?.effects.filter(effect => effect.target.variant.value == display_cap?.id) || [])

    // Helper function to get effect type name
    function getEffectTypeName(effectType: any): string {
        if (effectType && effectType.variant) {
            return effectType.variant.variant;
        }
        return 'Unknown';
    }

    $effect(() => {
        console.log(effects)
    })

    // Close function for opponent popup
    function closeOpponentPopup() {
        if (capType === 'inspected') {
            caps.close_inspected_cap();
        }
    }
</script>

<svelte:window 
    on:mousemove={handleMouseMove} 
    on:mouseup={handleMouseUp}
    on:touchmove={handleTouchMove}
    on:touchend={handleTouchEnd}
/>

{#if display_cap}
    {@const cap_type = caps.cap_types.find(cap_type => cap_type.id == display_cap.cap_type)}
    {#if cap_type}
        <div 
            class="cap-overlay" 
            class:opponent={is_opponent}
            class:mobile={window.innerWidth <= 768}
            style="left: {position.x}px; top: {position.y}px; width: {size.width}px; height: {size.height}px;"
            onmousedown={handleMouseDown}
            ontouchstart={handleTouchStart}
            role="button"
            tabindex="0"
        >
            <div class="cap-box">
                <div class="header">
                    <strong>{cap_type.name}</strong>
                    <div class="header-info">
                        <span>ID: {display_cap.id}</span>
                        {#if is_opponent}
                            <span class="opponent-label">Opponent</span>
                        {/if}
                    </div>
                    {#if capType === 'inspected'}
                        <button class="close-button" onclick={closeOpponentPopup}>×</button>
                    {/if}
                </div>
                
                <div class="content">
                    <div class="health">
                        Health: {Number(cap_type.base_health) - Number(display_cap.dmg_taken)}/{Number(cap_type.base_health)}
                    </div>
                    
                    <div class="stats">
                        <div>Move Cost: {cap_type.move_cost}</div>
                        <div>Attack Cost: {cap_type.attack_cost}</div>
                        <div>Attack Damage: {cap_type.attack_dmg}</div>
                        <div>Position: ({display_cap.position.x}, {display_cap.position.y})</div>
                    </div>

                    {#if cap_type.ability_description}
                        <div class="ability">
                            <div class="section-title">Ability</div>
                            <div class="ability-description">{cap_type.ability_description}</div>
                            <div class="ability-cost">Cost: {cap_type.ability_cost}</div>
                        </div>
                    {/if}

                    {#if effects.length > 0}
                        <div class="effects">
                            <div class="section-title">Active Effects</div>
                            {#each effects as effect}
                                <div class="effect-item">
                                    <span class="effect-type">{getEffectTypeName(effect.effect_type)}</span>
                                    <span class="effect-duration">({effect.remaining_triggers} turns)</span>
                                </div>
                            {/each}
                        </div>
                    {/if}
                </div>
            </div>
            
            <!-- Resize handle -->
            <div class="resize-handle"></div>
        </div>
    {/if}
{/if}

<style>
    .cap-overlay {
        position: fixed;
        z-index: 1000;
        background: white;
        border: 2px solid #333;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        min-width: 200px;
        min-height: 150px;
        max-width: 90vw;
        max-height: 90vh;
        overflow: hidden;
        cursor: move;
        user-select: none;
        font-size: 13px;
        resize: both;
    }

    .cap-overlay.mobile {
        font-size: 16px;
        min-width: 180px;
        min-height: 120px;
        border-radius: 12px;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
    }

    .cap-overlay:active {
        cursor: grabbing;
    }

    .cap-box {
        height: 100%;
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }

    .header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 12px;
        background: #f5f5f5;
        border-bottom: 1px solid #ddd;
        cursor: move;
        flex-shrink: 0;
    }

    .cap-overlay.mobile .header {
        padding: 12px 16px;
        touch-action: none;
    }

    .header strong {
        color: #333;
        font-size: 14px;
        margin: 0;
    }

    .cap-overlay.mobile .header strong {
        font-size: 18px;
    }

    .header-info {
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 2px;
    }

    .header-info span {
        color: #666;
        font-size: 11px;
    }

    .cap-overlay.mobile .header-info span {
        font-size: 14px;
    }

    .opponent-label {
        background: #ef4444;
        color: white;
        padding: 2px 6px;
        border-radius: 3px;
        font-size: 10px;
        font-weight: bold;
    }

    .cap-overlay.mobile .opponent-label {
        padding: 4px 8px;
        font-size: 12px;
        border-radius: 4px;
    }

    .cap-overlay.opponent {
        border: 2px solid #ef4444;
    }

    .cap-overlay.opponent .cap-box {
        border-color: #ef4444;
        background: #fef2f2;
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

    .cap-overlay.mobile .close-button {
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

    .content {
        color: #444;
        padding: 8px 12px;
        overflow-y: auto;
        flex: 1;
    }

    .cap-overlay.mobile .content {
        padding: 12px 16px;
    }

    .health {
        margin-bottom: 8px;
        font-weight: bold;
        color: #e74c3c;
        font-size: 12px;
    }

    .cap-overlay.mobile .health {
        font-size: 16px;
        margin-bottom: 12px;
    }

    .stats div {
        margin: 4px 0;
        color: #555;
        font-size: 11px;
    }

    .cap-overlay.mobile .stats div {
        margin: 8px 0;
        font-size: 14px;
    }

    .ability {
        margin-top: 12px;
        padding-top: 8px;
        border-top: 1px solid #eee;
    }

    .cap-overlay.mobile .ability {
        margin-top: 16px;
        padding-top: 12px;
    }

    .section-title {
        font-weight: bold;
        margin-bottom: 4px;
        color: #333;
        font-size: 12px;
    }

    .cap-overlay.mobile .section-title {
        font-size: 16px;
        margin-bottom: 8px;
    }

    .ability-description {
        margin-bottom: 4px;
        color: #666;
        font-size: 11px;
        line-height: 1.3;
    }

    .cap-overlay.mobile .ability-description {
        font-size: 14px;
        margin-bottom: 8px;
        line-height: 1.4;
    }

    .ability-cost {
        font-weight: bold;
        color: #8b5cf6;
        font-size: 11px;
    }

    .cap-overlay.mobile .ability-cost {
        font-size: 14px;
    }

    .effects {
        margin-top: 12px;
        padding-top: 8px;
        border-top: 1px solid #eee;
    }

    .cap-overlay.mobile .effects {
        margin-top: 16px;
        padding-top: 12px;
    }

    .effect-item {
        display: flex;
        justify-content: space-between;
        margin: 4px 0;
        padding: 2px 0;
        font-size: 11px;
    }

    .cap-overlay.mobile .effect-item {
        margin: 8px 0;
        padding: 4px 0;
        font-size: 14px;
    }

    .effect-type {
        font-weight: bold;
        color: #7c3aed;
    }

    .effect-duration {
        color: #666;
        font-size: 10px;
    }

    .cap-overlay.mobile .effect-duration {
        font-size: 12px;
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

    .cap-overlay.mobile .resize-handle {
        width: 24px;
        height: 24px;
        background: linear-gradient(135deg, transparent 50%, #666 50%);
    }

    .resize-handle:hover {
        background: linear-gradient(135deg, transparent 50%, #666 50%);
    }

    /* Touch optimization */
    @media (pointer: coarse) {
        .cap-overlay {
            touch-action: none;
        }
        
        .header {
            min-height: 44px;
        }
        
        .close-button {
            min-height: 44px;
            min-width: 44px;
        }
    }
</style>
