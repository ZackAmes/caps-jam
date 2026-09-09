<script lang="ts">
    import { T } from '@threlte/core';
    import { HTML, type EventMap } from '@threlte/extras';
    import { Tween, prefersReducedMotion } from 'svelte/motion';
    import { cubicOut } from 'svelte/easing';
    import { pieceSymbol } from '$lib/game/presentation';
    import type { ChainCap } from '@caps/game-core/types';
    let { cap, x, z, selected, oncell, onhover }: {cap:ChainCap; x:number; z:number; selected:boolean; oncell:(x:number,y:number)=>void; onhover:(id:number|null)=>void} = $props();
    const position = Tween.of(() => [x, z], {duration:() => prefersReducedMotion.current ? 0 : 180, easing:cubicOut});
</script>
<T.Group position={[position.current[0],0.27,position.current[1]]}
    onclick={(event:EventMap['onclick']) => { event.stopPropagation(); oncell(cap.x!,cap.y!); }}
    onpointerenter={(event:EventMap['onpointerenter']) => { if (event.nativeEvent.pointerType === 'mouse') onhover(cap.id); }}
    onpointerleave={() => onhover(null)}>
    <T.Mesh>
        <T.CylinderGeometry args={[0.26,0.32,0.34,24]} />
        <T.MeshStandardMaterial color={cap.playerSlot === 0 ? '#51a5ff' : '#ff7185'} roughness={0.35} metalness={0.15} />
    </T.Mesh>
    {#if selected || cap.shield > 0}
        <T.Mesh position={[0,-0.15,0]} rotation={[-Math.PI/2,0,0]}><T.RingGeometry args={[0.34,0.4,32]} /><T.MeshBasicMaterial color={selected ? '#ffffff' : '#93c5fd'} /></T.Mesh>
    {/if}
    <HTML position={[0,0.4,0]} center pointerEvents="none" zIndexRange={[10,1]}>
        <span class="token" class:selected><b>{pieceSymbol(cap.capType)}</b><small>{cap.health}{cap.shield ? ' ⛨' : ''}{cap.stunnedTurns ? ' ◌' : ''}</small></span>
    </HTML>
</T.Group>
<style>
    .token { display:flex; align-items:center; gap:3px; padding:2px 5px; border-radius:7px; background:#0b1220df; color:#f8fafc; border:1px solid #536885; font:16px system-ui; white-space:nowrap; }
    .token.selected { border-color:white; } small { font-size:10px; }
</style>
