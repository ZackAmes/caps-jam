<script lang="ts">
    import { onMount } from 'svelte';
    import { Canvas } from '@threlte/core';
    import LiveScene from './live-scene.svelte';
    import type { LayoutConfig } from '@caps/game-core/board';
    import type { AbilityStack, ChainCap, CapTypeDef } from '@caps/game-core/types';

    let { layout, caps, definitions, selectedId, targets, focusedCells, stack, oncell, onfailure }: {
        layout: LayoutConfig; caps: ChainCap[]; definitions: Map<number, CapTypeDef>;
        selectedId: number | null; targets: Map<string, string>; focusedCells: Set<string>; stack: AbilityStack;
        oncell: (x: number, y: number) => void; onfailure: () => void;
    } = $props();
    let viewport: HTMLDivElement;
    onMount(() => {
        // Context loss does not bubble; capture it from the child canvas.
        const element = viewport;
        element.addEventListener('webglcontextlost', onfailure, true);
        return () => element.removeEventListener('webglcontextlost', onfailure, true);
    });
</script>

<div class="viewport" bind:this={viewport}>
    <Canvas dpr={1.5}>
        <LiveScene {layout} {caps} {definitions} {selectedId} {targets} {focusedCells} {stack} {oncell} />
    </Canvas>
</div>

<style>
    .viewport { width: 100%; aspect-ratio: 1; min-height: 0; touch-action: pan-y pinch-zoom; overflow: hidden; border-radius: 12px; background: radial-gradient(ellipse at top, #20304a, #0b1220); }
</style>
