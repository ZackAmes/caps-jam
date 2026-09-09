<script lang="ts">
    import type { TurnRecord, CapTypeDef } from '@caps/game-core/types';
    import { describeImpact } from '@caps/game-core/stack';
    import { actionLabel, turnOutcomes } from './history';
    let { records, definitions, viewer, loading, error, hasOlder, onolder }: {
        records: TurnRecord[]; definitions: Map<number, CapTypeDef>; viewer:number|null;
        loading:boolean; error:string|null; hasOlder:boolean; onolder:()=>void;
    } = $props();
</script>
<section class="panel" id="turn-history" aria-label="Turn history">
    <h2>Turn history</h2>
    <p class="note">Confirmed actions and results, read directly from the game.</p>
    {#if loading}<p role="status">Loading turn history…</p>{/if}
    {#if error}<p role="status">{error}</p>{/if}
    {#if !records.length && !loading}<p class="note">No recorded turns yet. Turns before this upgrade have no action record.</p>{/if}
    <div class="records">
        {#each records as record, index (`${record.gameId}:${record.turn}`)}
            <details open={index === 0}>
                <summary>Turn {record.turn + 1} · {record.playerSlot === viewer ? 'You' : `Opponent · P${record.playerSlot + 1}`} · {record.actions.length ? `${record.actions.length} action${record.actions.length === 1 ? '' : 's'}` : 'Passed'}</summary>
                <ol>{#each record.actions as action}<li>{actionLabel(action, record.before, definitions)}</li>{/each}</ol>
                {#if !record.actions.length}<p class="note">No actions submitted.</p>{/if}
                <p class="note">Energy: {record.energyBefore} → {record.energyAfter}</p>
                {#each record.resolved as entry}<p class="resolution">Resolved #{entry.id}: {describeImpact(entry)}</p>{/each}
                {#each turnOutcomes(record, definitions) as result}<p class="outcome">{result}</p>{/each}
            </details>
        {/each}
    </div>
    {#if hasOlder}<button disabled={loading} onclick={onolder}>Load earlier turns</button>{/if}
</section>
<style>
    .panel { background:#111d30; border:1px solid #475569; border-radius:12px; padding:14px; }
    h2 { font-size:1rem; margin:0; } .note { color:#aebed3; font-size:0.76rem; line-height:1.5; }
    .records { max-height:420px; overflow:auto; }
    details { border-top:1px solid #334155; padding:9px 0; font-size:0.82rem; }
    summary { cursor:pointer; min-height:32px; line-height:1.5; padding:4px 0; color:#dde8f6; }
    ol { padding-left:20px; } li { padding:4px 0; line-height:1.5; }
    .outcome,.resolution { font-size:0.76rem; line-height:1.5; margin:5px 0; } .resolution { color:#fcd34d; }
    button { width:100%; min-height:44px; background:#1c2a40; color:#e2e8f0; border:1px solid #53647a; border-radius:7px; cursor:pointer; margin-top:10px; }
</style>
