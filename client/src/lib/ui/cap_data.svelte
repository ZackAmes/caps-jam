<script lang="ts">
	import type { Cap, CapType, Vec2 } from '../dojo/models.gen.ts';
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
        width: 420,
        height: 250
    });

    // Update position when render position changes (new click)
    $effect(() => {
        if (window.innerWidth <= 768) return;
        if (capType === 'selected' && caps.selected_cap_render_position) {
            position.x = caps.selected_cap_render_position.x;
            position.y = caps.selected_cap_render_position.y - 150;
        } else if (capType === 'inspected' && caps.inspected_cap_render_position) {
            position.x = caps.inspected_cap_render_position.x;
            position.y = caps.inspected_cap_render_position.y - 150;
        }
    });

    function handleMouseDown(e: MouseEvent) {
        if (window.innerWidth <= 768) return;
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
        if (window.innerWidth <= 768) return;
        if (isDragging) {
            position.x = e.clientX - dragOffset.x;
            position.y = e.clientY - dragOffset.y;
        } else if (isResizing) {
            size.width = Math.max(200, e.clientX - position.x);
            size.height = Math.max(150, e.clientY - position.y);
        }
    }

    function handleMouseUp() {
        if (window.innerWidth <= 768) return;
        isDragging = false;
        isResizing = false;
    }

    function handleTouchStart(e: TouchEvent) {
        if (window.innerWidth <= 768) return;
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
        if (window.innerWidth <= 768) return;
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
        if (window.innerWidth <= 768) return;
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

    const gridSize = 7;
    const radius = Math.floor(gridSize / 2);
    const gridCells = Array.from({ length: gridSize * gridSize });

    function isPatternHighlighted(x: number, y: number, range: Array<Vec2> | undefined): boolean {
        if (!range) return false;
        for (const vec of range) {
            if (Number(vec.x) === 0 && Number(vec.y) === 0) continue;
            if (Math.abs(x) === Number(vec.x) && Math.abs(y) === Number(vec.y)) {
                return true;
            }
        }
        return false;
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
            class="cap-data-container" 
            class:opponent={is_opponent}
            class:desktop-popup={typeof window !== 'undefined' && window.innerWidth > 768}
            class:mobile-static={typeof window !== 'undefined' && window.innerWidth <= 768}
            style={typeof window !== 'undefined' && window.innerWidth > 768 ? `left: ${position.x}px; top: ${position.y}px; width: ${size.width}px; height: ${size.height}px;` : ''}
            onmousedown={handleMouseDown}
            ontouchstart={handleTouchStart}
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
                    <div class="top-content">
                        <div class="main-info">
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
                        </div>

                        <div class="patterns-container">
                             {#if cap_type.attack_range && cap_type.attack_range.length > 0}
                                <div class="pattern-section">
                                    <div class="section-title">Attack Pattern</div>
                                    <div class="pattern-grid">
                                        {#each gridCells as _, i}
                                            {@const x = (i % gridSize) - radius}
                                            {@const y = Math.floor(i / gridSize) - radius}
                                            <div 
                                                class="cell"
                                                class:highlight={isPatternHighlighted(x, y, cap_type.attack_range)}
                                                class:center={x === 0 && y === 0}
                                                title={`(${x}, ${y})`}
                                            >
                                                {#if x === 0 && y === 0}C{/if}
                                            </div>
                                        {/each}
                                    </div>
                                </div>
                            {/if}

                            {#if cap_type.ability_range && cap_type.ability_range.length > 0}
                                <div class="pattern-section">
                                    <div class="section-title">Ability Pattern</div>
                                    <div class="pattern-grid">
                                        {#each gridCells as _, i}
                                            {@const x = (i % gridSize) - radius}
                                            {@const y = Math.floor(i / gridSize) - radius}
                                            <div 
                                                class="cell"
                                                class:highlight={isPatternHighlighted(x, y, cap_type.ability_range)}
                                                class:center={x === 0 && y === 0}
                                                title={`(${x}, ${y})`}
                                            >
                                                {#if x === 0 && y === 0}C{/if}
                                            </div>
                                        {/each}
                                    </div>
                                </div>
                            {/if}
                        </div>
                    </div>


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

            {#if typeof window !== 'undefined' && window.innerWidth > 768}
                <div class="resize-handle"></div>
            {/if}
        </div>
    {/if}
{/if}

<style>
    .cap-data-container {
        background: white;
        border: 2px solid #333;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        overflow: hidden;
    }

    .desktop-popup {
        position: fixed;
        z-index: 1000;
        min-width: 200px;
        min-height: 150px;
        max-width: 90vw;
        max-height: 90vh;
        cursor: move;
        user-select: none;
        font-size: 13px;
        resize: both;
    }

    .mobile-static {
        margin: 1rem 0;
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

    .cap-data-container.opponent {
        border: 2px solid #ef4444;
    }

    .cap-data-container.opponent .cap-box {
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

    .top-content {
        display: flex;
        gap: 16px;
    }

    .main-info {
        flex: 1;
    }

    .patterns-container {
        display: flex;
        flex-direction: column;
        gap: 12px;
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

    .pattern-grid {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        border: 1px solid #ccc;
        aspect-ratio: 1 / 1;
        max-width: 160px;
        margin-top: 8px;
    }

    .cell {
        border: 1px solid #eee;
        display: flex;
        justify-content: center;
        align-items: center;
        font-size: 0.8em;
    }

    .cell.center {
        background-color: #aaa;
        color: white;
        font-weight: bold;
    }

    .cell.highlight {
        background-color: #fca5a5;
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

    .resize-handle:hover {
        background: linear-gradient(135deg, transparent 50%, #666 50%);
    }

    @media (max-width: 768px) {
        .top-content {
            flex-direction: column;
        }

        .header, .content {
            padding: 12px 16px;
        }
        .header-info span, .stats div, .ability-description, .ability-cost, .effect-item {
            font-size: 1rem;
        }
    }
</style>
