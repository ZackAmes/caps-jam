# Frontend state and action history (rules v5)

This is an additive upgrade of the September 8 world. Existing games, piece IDs,
boards, hands and pending abilities are preserved. New games have seven pieces per
side, including a Negator. Existing games keep their original roster.

## Stack targeting

`ActionType::StackAbility(u64)` is appended to the action enum (variant 3). Its payload
is a stable effect ID, not board coordinates or an index into the stack. The original
Play, Move and Ability encodings are unchanged. `TargetType` adds AnyPending (6),
EnemyPending (7) and AllyPending (8). Core validation checks the source is on board,
not stunned, unused this turn, has enough energy, and the target exists with the right
side relation. Stack targets have no spatial range. Sets implement
`activate_stack_ability(ctx, target_id)` and return the same validated SetOps as before.

The reference Negator (type 6, 6 HP, 1 attack, 2 energy) negates an enemy entry immediately
during its owner's normal turn. It consumes that piece's activation, not the normal
move/deploy action. Select the Negator, activate its ability, then choose an eligible
entry in the stack panel. Negation is previewed until the turn is submitted. Stale IDs
revert instead of accidentally targeting another entry. The bot generates the same
explicit stack-target actions.

The stack panel shows source, owner, announcement turn, raw readiness, resolution order,
and the earliest resolution boundary allowed by all newer entries. Announcements added
later can change that boundary. Inspect an effect to highlight its footprint and see
currently affected pieces. Eligibility is re-evaluated when the effect resolves.

## History without Torii

`TurnRecord` is keyed by `(game_id, turn)` and is written atomically with the turn. It
stores submitted actions in order, before/after piece snapshots, before/after stacks,
actual stack resolution order, and the acting player's energy before/after spending.
`get_turn(game_id, turn)` returns an optional record. Passes are recorded too.

The client reads four records at a time over RPC. It shows the opponent's latest actions
next to the board and expandable results in turn history. Move/attack targets are shown
exactly as submitted; final positions, health, shield, capture/death and stun changes
come from the recorded snapshots. Records are available only for turns after this upgrade;
missing earlier records are not reconstructed or presented as exact history.

## Submission and refresh

The planned board stays visible through sending, confirmation and synchronization.
Controls stay locked once a transaction hash exists until a successful receipt and a
newer game snapshot are observed. A timeout does not automatically resubmit the turn.
Reverted transactions unlock the retained plan. RPC reads have deadlines and retry on
subsequent polls. Refresh is also available manually.

The client reads the game, related hands/stack/definitions, then the game again. If the
turn changed, the mixed snapshot is discarded and re-read. Opponent updates and updates
from another tab are checked every five seconds, and on returning to the tab. History
loads separately so a history failure does not prevent board play.

## Responsive layout

Desktop places a sticky board beside stack, piece information, hand, turn controls and
history. At 850 px and below it uses one column, with the submit control fixed above the
safe area. A compact stack summary links to the detailed list. Inputs and buttons have
at least 44 px height. Hand pieces have an explicit Info control for touch devices.
Both board renderers share selected targets, effect highlights and A1–E5 coordinates.
The 2D renderer remains available if WebGL fails.
