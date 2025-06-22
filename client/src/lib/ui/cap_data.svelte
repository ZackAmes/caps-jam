<script lang="ts">
	import type { Cap, CapType } from '../dojo/models.gen.ts';
    import { caps } from '../stores/caps.svelte';

    // Props to specify which cap to display
    let { capType = 'selected' }: { capType?: 'selected' | 'inspected' } = $props();

    let isDragging = false;
    let dragOffset = { x: 0, y: 0 };
    
    // Initialize position based on click coordinates, then allow dragging
    let position = $state({
        x: capType === 'selected' ? 20 : 260, 
        y: capType === 'selected' ? 20 : 20
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

<svelte:window on:mousemove={handleMouseMove} on:mouseup={handleMouseUp} />

{#if display_cap}
    {@const cap_type = caps.cap_types.find(cap_type => cap_type.id == display_cap.cap_type)}
    {#if cap_type}
        <div 
            class="cap-overlay" 
            class:opponent={is_opponent}
            style="left: {position.x + 50}px; top: {position.y - 100}px;"
            onmousedown={handleMouseDown}
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
                                    <span class="effect-id">ID: {effect.effect_id}</span>
                                </div>
                            {/each}
                        </div>
                    {/if}
                </div>
            </div>
        </div>
    {/if}
{/if}

<style>
    .cap-overlay {
        position: fixed;
        z-index: 1000;
        cursor: move;
        user-select: none;
    }

    .cap-box {
        background: white;
        border: 2px solid #333;
        border-radius: 6px;
        padding: 12px;
        width: 220px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        font-family: Arial, sans-serif;
        font-size: 14px;
    }

    /* Mobile responsive cap data */
    @media (max-width: 768px) {
        .cap-overlay {
            /* Adjust positioning for mobile to avoid off-screen issues */
            max-width: calc(100vw - 1rem);
            left: 0.5rem !important;
            right: 0.5rem !important;
            width: auto !important;
        }

        .cap-box {
            width: 100%;
            max-width: none;
            padding: 16px;
            font-size: 16px;
            border-radius: 8px;
            max-height: calc(100vh - 4rem);
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

    .header-info {
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 2px;
    }

    .header-info span {
        color: #666;
        font-size: 12px;
    }

    @media (max-width: 768px) {
        .header-info span {
            font-size: 14px;
        }
    }

    .opponent-label {
        background: #ef4444;
        color: white;
        padding: 2px 6px;
        border-radius: 3px;
        font-size: 10px;
        font-weight: bold;
    }

    @media (max-width: 768px) {
        .opponent-label {
            padding: 4px 8px;
            font-size: 12px;
            border-radius: 4px;
        }
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

    @media (max-width: 768px) {
        .close-button {
            font-size: 24px;
            width: 32px;
            height: 32px;
            padding: 4px;
        }
    }

    .close-button:hover {
        color: #333;
    }

    .content {
        color: #444;
    }

    .health {
        margin-bottom: 8px;
        font-weight: bold;
        color: #e74c3c;
    }

    @media (max-width: 768px) {
        .health {
            font-size: 18px;
            margin-bottom: 12px;
        }
    }

    .stats div {
        margin: 4px 0;
        color: #555;
    }

    @media (max-width: 768px) {
        .stats div {
            margin: 8px 0;
            font-size: 16px;
        }
    }

    .ability {
        margin-top: 12px;
        padding-top: 8px;
        border-top: 1px solid #eee;
    }

    @media (max-width: 768px) {
        .ability {
            margin-top: 16px;
            padding-top: 12px;
        }
    }

    .section-title {
        font-weight: bold;
        color: #333;
        margin-bottom: 6px;
        font-size: 15px;
    }

    @media (max-width: 768px) {
        .section-title {
            font-size: 18px;
            margin-bottom: 8px;
        }
    }

    .ability-description {
        color: #444;
        font-style: italic;
        margin-bottom: 4px;
        line-height: 1.3;
    }

    .ability-cost {
        color: #666;
        font-size: 12px;
    }

    .effects {
        margin-top: 12px;
        padding-top: 8px;
        border-top: 1px solid #eee;
    }

    .effect-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin: 4px 0;
        padding: 4px 6px;
        background: #f8f9fa;
        border-radius: 3px;
    }

    .effect-type {
        color: #2c3e50;
        font-weight: 500;
    }

    .effect-id {
        color: #666;
        font-size: 12px;
    }
</style>
