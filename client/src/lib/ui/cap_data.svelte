<script lang="ts">
	import type { Cap, CapType } from '../dojo/models.gen.ts';
    import { caps } from '../stores/caps.svelte';

    let isDragging = false;
    let dragOffset = { x: 0, y: 0 };
    let position = { x: 20, y: 20 };

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

    let effects = $derived(caps.game_state?.effects.filter(effect => effect.target.variant.value == caps.selected_cap!.id))

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
</script>

<svelte:window on:mousemove={handleMouseMove} on:mouseup={handleMouseUp} />

{#if caps.selected_cap}
    {@const cap_type = caps.cap_types.find(cap_type => cap_type.id == caps.selected_cap!.cap_type)}
    {#if cap_type}
        <div 
            class="cap-overlay" 
            style="left: {position.x}px; top: {position.y}px;"
            onmousedown={handleMouseDown}
            role="button"
            tabindex="0"
        >
            <div class="cap-box">
                <div class="header">
                    <strong>{cap_type.name}</strong>
                    <span>ID: {caps.selected_cap.id}</span>
                </div>
                
                <div class="content">
                    <div class="health">
                        Health: {Number(cap_type.base_health) - Number(caps.selected_cap.dmg_taken)}/{Number(cap_type.base_health)}
                    </div>
                    
                    <div class="stats">
                        <div>Move Cost: {cap_type.move_cost}</div>
                        <div>Attack Cost: {cap_type.attack_cost}</div>
                        <div>Attack Damage: {cap_type.attack_dmg}</div>
                        <div>Position: ({caps.selected_cap.position.x}, {caps.selected_cap.position.y})</div>
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

    .header span {
        color: #666;
        font-size: 12px;
    }

    .content {
        color: #444;
    }

    .health {
        margin-bottom: 8px;
        font-weight: bold;
        color: #e74c3c;
    }

    .stats div {
        margin: 4px 0;
        color: #555;
    }

    .ability {
        margin-top: 12px;
        padding-top: 8px;
        border-top: 1px solid #eee;
    }

    .section-title {
        font-weight: bold;
        color: #333;
        margin-bottom: 6px;
        font-size: 15px;
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
