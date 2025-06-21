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
</script>

<svelte:window on:mousemove={handleMouseMove} on:mouseup={handleMouseUp} />

{#if caps.selected_cap}
    {@const cap_type = caps.cap_types.find(cap_type => cap_type.id == caps.selected_cap!.cap_type)}
    {#if cap_type}
        <div 
            class="cap-overlay" 
            style="left: {position.x}px; top: {position.y}px;"
            on:mousedown={handleMouseDown}
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
</style>
