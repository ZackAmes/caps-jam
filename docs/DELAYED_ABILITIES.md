# Delayed abilities and the stack (rules v4)

Deployed to the fresh September 8, 2026 v4 Sepolia world. Client and bot use the
same v4 manifest. This extends the v3 passive/path foundation.

## Timing and responses

Abilities can announce a delayed effect instead of immediately changing pieces. Energy
is paid and the piece's once-per-turn activation is consumed when it announces the effect.
An invalid announcement reverts the transaction. Countering an accepted effect does not
refund that cost or restore the activation.

Delay counts complete future **player turns**, excluding the announcing turn. A delay
of one gives the opponent one full turn. If announced on global turn T, the earliest
resolution boundary is T + delay + 1. Supported delays are 1 through 8. There are no
wall-clock timers, and offline players do not automatically pass.

Responses happen through normal turns: move out, shield/heal, activate a counter ability,
or announce another delayed effect. This version does not add out-of-turn activations,
a separate priority holder, or consecutive-pass actions.

The stack is strict **last in, first out**. The newest pending effect must resolve before
anything underneath it. An unready top blocks older effects even if their delay has elapsed.
Thus, another delayed announcement can extend the response window for an older effect.

| Player turn | Action | At turn end |
|---|---|---|
| A, turn 0 | Announce row damage with delay 1 | Damage remains pending |
| B, turn 1 | Announce row shielding with delay 1 | Shield is not ready, so older damage waits |
| A, turn 2 | Move or pass | Shield resolves first, then damage |

When the top is ready, resolve it and continue draining ready entries from the top. There
is no additional priority pause between these resolutions in the turn-based version.
Existing immediate abilities still resolve immediately; only `Schedule` adds to the stack.

## What is fixed and what is live

An entry stores its stable ID, source piece ID, controlling player slot, announcement and
readiness turns, effect kind, amount, relation filter, and target selector. Entries are
immutable after announcement; counters remove entries. IDs increase and are never reused
within a game. The stack is public, oldest first in the API and newest first in the UI.

The source does not need to survive or remain on the board. The fixed row/column/zone does
not move with it. Eligible occupants are selected at resolution, so escaping a row avoids
the effect and moving into it makes a piece eligible. Allies and enemies use the announcing
player's slot, including in solo games that share an account.

Supported selectors:

- A specific piece ID: follows that piece's movement; no effect if it is dead or on the bench at resolution.
- A fixed row or column: affects the eligible on-board occupants at resolution.
- A fixed center and path radius: uses the shared shortest-path distance, ignoring intervening occupants.

All selectors can filter allies, enemies, or both. The first supported delayed impact kinds
are damage, healing, and shielding. This is an explicit, extensible vocabulary; arbitrary
set callbacks and delayed movement/summoning are not implemented.

A single area impact is simultaneous: eligibility and passive damage reduction are read
from one board snapshot before any affected piece is changed. Killing an aura source within
that impact does not remove its protection halfway through the same impact. The next stack
entry sees the updated board. Damage uses shields; healing clamps at the target's real max
health; shielding saturates at the existing shield limit. Missing targets fizzle harmlessly.

## Turn boundary and victory

Resolution order is:

1. Finish the player's queued actions, checking goals/captures after each ability/action.
2. Apply normal end-turn effects and regeneration, then board checks.
3. Resolve the ready top of the stack, with board checks between entries.
4. Advance the turn and prepare the next player's income/start-turn effects.

A goal wins immediately. Pending effects are cleared when a game ends and cannot reverse
the result. Stack resolution does not cost either player an action or energy. Captures at
this boundary use the closing turn for cooldown accounting.

## Authoring an ability

A set can return this operation for the example row blast:

```cairo
SetOp::Schedule(Schedule {
    delay: 1,
    impact: DelayedImpact {
        kind: ImpactKind::Damage,
        selection: Selection::Row(target.y),
        relation: Relation::Any,
        amount: 4,
    },
})
```

Blaster now uses this operation (3 energy, target anchor within 3 path steps). The other
reference abilities keep their existing immediate behavior. Targeting an anchor chooses
its entire row; the eventual row occupants are not individually range-checked again.

Sets receive the current public stack as `AbilityContext.stack`. A counter ability emits
`SetOp::CounterPending(id)`. It can counter any chosen pending entry, including a buried one;
countering a missing ID is a harmless no-op. The ordinary ability ownership, cost, targeting,
and turn restrictions still apply. Counter behavior is tested with a test-only set; the
reference roster has not gained a dedicated counter piece.

Storage is `AbilityStack`, with a maximum of 32 pending entries per game. The existing
operation budget also limits how many entries a single activation can announce. Scheduling
past the limit rejects the transaction rather than dropping an effect silently.

## Client, bot, and deployment

The client displays public pending effects and readiness, highlights threatened damage rows,
and previews newly queued announcements without applying their damage immediately. The AI
reads the same stack and scores candidate moves after effects due at the current turn end;
its estimate of newly announced effects is deliberately simple and does not predict opponent
responses. Its forecast covers stack impacts, not the older timed-status-effect system.

`get_stack(game_id)` exposes the stored state. `rules_version()` is 4, and the client/bot
reject older deployments. The new model and the changed set context require a coordinated
fresh deployment of world/actions/Set Zero, manifest synchronization, and a new bot
checkpoint. Do not reuse a checkpoint from a different world.

Tests cover turn windows, LIFO blocking, shielding responses, counters, source death, live
row selection, goal precedence, saturation, area mitigation, serialization, and AI escape.
