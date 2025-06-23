<script lang="ts">
	import type { Cap, CapType } from '../dojo/models.gen.ts';
    import { caps } from '../stores/caps.svelte';

    // Props to specify which cap to display
    let { capType = 'selected' }: { capType?: 'selected' | 'inspected' } = $props();

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

{#if display_cap}
    {@const cap_type = caps.cap_types.find(cap_type => cap_type.id == display_cap.cap_type)}
    {#if cap_type}
        <div 
            class="cap-container" 
            class:opponent={is_opponent}
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
        </div>
    {/if}
{/if}

<style>
    .cap-container {
        background: white;
        border: 2px solid #333;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        margin: 1rem 0;
        overflow: hidden;
        width: 100%;
        box-sizing: border-box;
    }

    .cap-box {
        height: 100%;
        display: flex;
        flex-direction: column;
    }

    .header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 12px;
        background: #f5f5f5;
        border-bottom: 1px solid #ddd;
        flex-shrink: 0;
    }

    .header strong {
        color: #333;
        font-size: 1.1em;
        margin: 0;
    }

    .header-info {
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        gap: 2px;
    }

    .header-info span {
        color: #666;
        font-size: 0.8em;
    }

    .opponent-label {
        background: #ef4444;
        color: white;
        padding: 2px 6px;
        border-radius: 3px;
        font-size: 0.75em;
        font-weight: bold;
    }

    .cap-container.opponent {
        border: 2px solid #ef4444;
    }

    .cap-container.opponent .cap-box {
        background: #fef2f2;
    }

    .close-button {
        background: none;
        border: none;
        font-size: 1.2em;
        cursor: pointer;
        color: #666;
        padding: 0;
        margin-left: 8px;
        min-height: 24px;
        min-width: 24px;
    }

    .close-button:hover {
        color: #333;
    }

    .content {
        color: #444;
        padding: 8px 12px;
        overflow-y: auto;
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

    .ability, .effects {
        margin-top: 12px;
        padding-top: 8px;
        border-top: 1px solid #eee;
    }

    .section-title {
        font-weight: bold;
        margin-bottom: 4px;
        color: #333;
    }

    .ability-description {
        margin-bottom: 4px;
        color: #666;
        line-height: 1.3;
    }

    .ability-cost {
        font-weight: bold;
        color: #8b5cf6;
    }

    .effect-item {
        display: flex;
        justify-content: space-between;
        margin: 4px 0;
    }

    .effect-type {
        font-weight: bold;
        color: #7c3aed;
    }

    .effect-duration {
        color: #666;
        font-size: 0.9em;
    }

    @media (max-width: 768px) {
        .header, .content {
            padding: 12px 16px;
        }
        .header-info span, .stats div, .ability-description, .ability-cost, .effect-item {
            font-size: 1rem;
        }
    }
</style>
