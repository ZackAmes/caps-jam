<script lang="ts">
    import { T } from '@threlte/core';
    import { HTML, interactivity, type EventMap } from '@threlte/extras';
    import { pathEdges } from '$lib/game/presentation';
    import { pathDistance, type LayoutConfig } from '@caps/game-core/board';
    import type { AbilityStack, ChainCap, CapTypeDef } from '@caps/game-core/types';

    let { layout, caps, definitions, selectedId, targets, focusedCells, stack, oncell }: {
        layout: LayoutConfig; caps: ChainCap[]; definitions: Map<number, CapTypeDef>;
        selectedId: number | null; targets: Map<string, string>; focusedCells: Set<string>; stack: AbilityStack;
        oncell: (x: number, y: number) => void;
    } = $props();
    interactivity();
    let tiles = $derived(Array.from({length: layout.width * layout.height}, (_, i) => ({x: i % layout.width, y: Math.floor(i / layout.width)})));
    const wx = (x: number) => x - (layout.width - 1) / 2;
    const wz = (y: number) => y - (layout.height - 1) / 2;
    function danger(x: number, y: number) {
        return stack.entries.some(entry => {
            if (entry.impact.kind !== 'Damage') return false;
            const s = entry.impact.selection;
            if (s.kind === 'Row') return s.index === y;
            if (s.kind === 'Column') return s.index === x;
            if (s.kind === 'Piece') return caps.some(c => c.id === s.id && c.x === x && c.y === y);
            return pathDistance(layout, [s.x, s.y], [x, y]) <= s.radius;
        });
    }
    const colors: Record<string, string> = {move: '#14b8a6', fight: '#e45b62', ability: '#a78bfa'};
</script>

<T.PerspectiveCamera makeDefault position={[0, 7.8, 5.5]} fov={43} oncreate={(camera) => camera.lookAt(0, 0, 0)} />
<T.AmbientLight intensity={1.4} />
<T.DirectionalLight position={[-3, 8, 4]} intensity={2.2} />
<T.DirectionalLight position={[5, 3, -4]} intensity={0.8} color="#8baaff" />
<T.Mesh position={[0, -0.24, 0]}>
    <T.BoxGeometry args={[layout.width + 0.25, 0.32, layout.height + 0.25]} />
    <T.MeshStandardMaterial color="#101b2e" roughness={0.85} />
</T.Mesh>

{#each tiles as tile (`${tile.x},${tile.y}`)}
    {@const walkable = layout.isWalkable(tile.x, tile.y)}
    {@const target = targets.get(`${tile.x},${tile.y}`)}
    {@const goal = tile.x === 2 && (tile.y === 0 || tile.y === 4)}
    {@const energy = tile.y === 2 && (tile.x === 0 || tile.x === 4)}
    {@const threatened = walkable && danger(tile.x, tile.y)}
    <T.Mesh position={[wx(tile.x), walkable ? 0 : -0.09, wz(tile.y)]}
        onclick={(event: EventMap['onclick']) => { event.stopPropagation(); if (walkable) oncell(tile.x, tile.y); }}>
        <T.BoxGeometry args={[0.91, walkable ? 0.16 : 0.025, 0.91]} />
        <T.MeshStandardMaterial color={target ? colors[target] : focusedCells.has(`${tile.x},${tile.y}`) ? '#7651ae' : goal ? tile.y === 0 ? '#244b83' : '#783446' : energy ? '#78612c' : walkable ? '#33455f' : '#172338'}
            emissive={threatened ? '#e98a19' : target ? colors[target] : '#000000'} emissiveIntensity={threatened ? 0.35 : 0.12} roughness={0.7} />
    </T.Mesh>
    {#if walkable && (goal || energy)}
        <HTML position={[wx(tile.x), 0.12, wz(tile.y) + 0.32]} center pointerEvents="none" zIndexRange={[8, 1]}>
            <span class="tile-label">{goal ? `P${tile.y === 0 ? 1 : 2} BASE` : '+1 ENERGY'}</span>
        </HTML>
    {/if}
    {#if threatened}
        <T.Mesh position={[wx(tile.x), 0.095, wz(tile.y)]} rotation={[-Math.PI / 2, 0, 0]}>
            <T.RingGeometry args={[0.36, 0.41, 4]} />
            <T.MeshBasicMaterial color="#ffb547" />
        </T.Mesh>
    {/if}
{/each}

{#each Array.from({length:layout.width}, (_,i)=>i) as x}
    <HTML position={[wx(x),0.12,-layout.height / 2 - 0.13]} center pointerEvents="none" zIndexRange={[8,1]}><span class="axis-label">{String.fromCharCode(65+x)}</span></HTML>
{/each}
{#each Array.from({length:layout.height}, (_,i)=>i) as y}
    <HTML position={[-layout.width / 2 - 0.13,0.12,wz(y)]} center pointerEvents="none" zIndexRange={[8,1]}><span class="axis-label">{y+1}</span></HTML>
{/each}
{#each pathEdges(layout) as edge}
    <T.Mesh position={[wx((edge.x1 + edge.x2) / 2), 0.1, wz((edge.y1 + edge.y2) / 2)]}
        rotation={[0, Math.atan2(edge.x2 - edge.x1, edge.y2 - edge.y1), 0]}>
        <T.BoxGeometry args={[0.04, 0.02, Math.hypot(edge.x2 - edge.x1, edge.y2 - edge.y1)]} />
        <T.MeshBasicMaterial color="#afc3de" />
    </T.Mesh>
{/each}

{#each caps.filter(c => !c.dead && c.x !== null && c.y !== null) as cap (cap.id)}
    <T.Group position={[wx(cap.x!), 0.27, wz(cap.y!)]}
        onclick={(event: EventMap['onclick']) => { event.stopPropagation(); oncell(cap.x!, cap.y!); }}>
        <T.Mesh>
            <T.CylinderGeometry args={[0.26, 0.32, 0.34, 24]} />
            <T.MeshStandardMaterial color={cap.playerSlot === 0 ? '#51a5ff' : '#ff7185'} roughness={0.35} metalness={0.15} />
        </T.Mesh>
        {#if cap.id === selectedId || cap.shield > 0}
            <T.Mesh position={[0, -0.15, 0]} rotation={[-Math.PI / 2, 0, 0]}>
                <T.RingGeometry args={[0.34, 0.4, 32]} />
                <T.MeshBasicMaterial color={cap.id === selectedId ? '#ffffff' : '#93c5fd'} />
            </T.Mesh>
        {/if}
        <HTML position={[0, 0.46, 0]} center pointerEvents="none" zIndexRange={[10, 1]}>
            <span class="piece-label" class:selected={cap.id === selectedId}>
                <b>{definitions.get(cap.capType)?.name ?? `Piece ${cap.capType}`}</b>
                <span>♥ {cap.health}{cap.shield ? ` · ⛨ ${cap.shield}` : ''}{cap.stunnedTurns ? ' · Stunned' : ''}</span>
            </span>
        </HTML>
    </T.Group>
{/each}

<style>
    .axis-label { color:#d1dcec; font:700 11px system-ui; }
    .tile-label { color: #dde8f9; font: 700 8px system-ui; white-space: nowrap; text-shadow: 0 1px 3px #000; }
    .piece-label { display: flex; flex-direction: column; align-items: center; color: #f8fafc; background: #0b1220e8; border: 1px solid #536885; border-radius: 5px; padding: 3px 5px; font: clamp(10px, 1vw, 13px) system-ui; white-space: nowrap; }
    .piece-label.selected { border-color: white; }
    .piece-label span { color: #cedbee; font-size: 9px; }
</style>
