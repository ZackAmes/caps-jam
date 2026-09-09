<script lang="ts">
    import { describeImpact, canTargetPending, selectedBy } from '@caps/game-core/stack';
    import type { AbilityStack, ChainCap, CapTypeDef, StackEntry } from '@caps/game-core/types';
    import type { LayoutConfig } from '@caps/game-core/board';
    import { effectTiming, resolutionBoundary } from './presentation';
    let { stack, confirmedId, turn, viewer, caps, definitions, layout, actor, targeting, canActivate, focusedId, onfocus, ontarget, oncancel }: {
        stack: AbilityStack; confirmedId: number; turn: number; viewer: number | null; caps: ChainCap[];
        definitions: Map<number, CapTypeDef>; layout: LayoutConfig; actor: ChainCap | undefined;
        targeting: boolean; canActivate: boolean; focusedId: number | null;
        onfocus: (id: number | null) => void; ontarget: (id: number) => void; oncancel: () => void;
    } = $props();
    const name = (id: number) => { const c = caps.find(c => c.id === id); return `${c ? definitions.get(c.capType)?.name ?? 'Piece' : 'Piece'} #${id}`; };
    function eligible(entry: StackEntry) { return !!actor && canTargetPending(definitions.get(actor.capType)?.abilityTarget ?? 0, actor.playerSlot, entry); }
</script>
<section class="panel" id="ability-stack" aria-label="Ability stack">
    <div class="heading"><h2>Ability stack <span>{stack.entries.length}</span></h2>{#if focusedId !== null}<button onclick={() => onfocus(null)}>Clear highlight</button>{/if}</div>
    {#if targeting}
        <div class="targeting" role="status">Choose an effect for {actor ? name(actor.id) : 'your piece'}. <button onclick={oncancel}>Cancel targeting</button></div>
    {/if}
    <p class="note">Newest resolves first. Respond on your turn. Times below assume no new effects are added.</p>
    {#if !stack.entries.length}<p class="empty">No pending abilities.</p>{/if}
    <div class="entries">
        {#each [...stack.entries].reverse() as entry, order (entry.id)}
            {@const source = caps.find(c => c.id === entry.sourceId)}
            {@const affected = caps.filter(c => selectedBy(entry, c, layout))}
            <article class:focused={focusedId === entry.id} class:eligible={targeting && eligible(entry)}>
                <button class="inspect" onclick={() => onfocus(focusedId === entry.id ? null : entry.id)} aria-pressed={focusedId === entry.id}>
                    <span class="eyebrow">{order === 0 ? 'TOP' : `RESOLVES ${order + 1}`} · #{entry.id} · {entry.playerSlot === viewer ? 'You' : `P${entry.playerSlot + 1}`}</span>
                    <strong>{describeImpact(entry)}</strong>
                    <span>Source: {name(entry.sourceId)}{!source || source.x === null ? ' · left board; effect remains' : ''}</span>
                    <b class="timing">{effectTiming(entry, stack, turn, viewer)}</b>
                    <span>With this stack: end of turn {resolutionBoundary(entry, stack, turn)}.</span>
                    <span class="note">{entry.id > confirmedId ? 'Planned — not yet submitted' : `Announced on turn ${entry.announcedTurn + 1}`} · earliest: end of turn {entry.readyTurn}</span>
                </button>
                <p class="affected">Currently affected: {affected.map(c => name(c.id)).join(', ') || 'no pieces'}. Targets are checked again at resolution.</p>
                {#if targeting}
                    <button class="negate" disabled={!canActivate || !eligible(entry)} onclick={() => ontarget(entry.id)}>
                        {eligible(entry) ? `Negate #${entry.id} · ${actor ? definitions.get(actor.capType)?.abilityCost ?? 0 : 0} energy` : 'Not a legal target for this ability'}
                    </button>
                {/if}
            </article>
        {/each}
    </div>
</section>
<style>
    .panel { background: #111d30; border: 1px solid #475569; border-radius: 12px; padding: 14px; scroll-margin-top: 12px; }
    .heading { display:flex; align-items:center; justify-content:space-between; gap:8px; }
    h2 { margin:0; font-size:1rem; } h2 span { color:#fbbf24; }
    button { font:inherit; color:inherit; cursor:pointer; border:1px solid #53647a; background:#1c2a40; border-radius:7px; min-height:44px; padding:8px; }
    .heading button { font-size:0.75rem; }
    .note,.affected { font-size:0.76rem; color:#aebed3; line-height:1.5; }
    .empty { color:#aebed3; font-size:0.85rem; }
    .entries { max-height:460px; overflow:auto; overscroll-behavior:contain; }
    article { border:1px solid #475569; border-radius:8px; margin-top:10px; overflow:hidden; }
    article.focused { border-color:#c4b5fd; } article.eligible { border-color:#a78bfa; }
    .inspect { width:100%; display:flex; flex-direction:column; gap:7px; text-align:left; border:0; border-radius:0; background:transparent; font-size:0.82rem; }
    .eyebrow { font-size:0.69rem; letter-spacing:0.07em; color:#e7c588; }
    .timing { color:#fcd34d; font-weight:600; }
    .affected { margin:0; padding:0 8px 8px; }
    .targeting { background:#31254a; padding:10px; margin-top:10px; border-radius:7px; font-size:0.85rem; }
    .negate { width:calc(100% - 16px); margin:0 8px 8px; background:#513577; }
    button:disabled { opacity:0.45; cursor:not-allowed; }
    @media(max-width:700px) { .entries { max-height:330px; } }
</style>
