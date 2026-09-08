# Playtesting rules v4

The client and independent bot use the same September 8, 2026 Sepolia deployment.
Old-world game IDs are separate and cannot be resumed in this client.

## Play against the bot

1. Open `/game`, choose **Use test account**, select a board, then **Play against Bot**.
2. Tap a hand piece to deploy at your base. Tap your board piece and a highlighted
   connected square to move or attack. The default 3D board uses tap/click controls.
   Switch to **2D** above the board for the flat board and drag controls.
3. Inspect a piece to read its ability and passive conditions. Abilities spend energy;
   deploying or moving spends the normal action. A Runner can grant an extra move.
4. **Submit Turn** commits your plan. **Pass turn** ends a turn with no actions.
   Undoing a planned action also removes actions after it.
5. Wait for the bot. It polls every 15 seconds; transaction confirmation can take longer.
   The page refreshes while waiting. **Copy link** shares the game; **Resume game**
   restores it after a refresh.

Both players' hands are public. The current test client intentionally uses one shared
human account, so testers should create separate games and avoid controlling the same
one simultaneously. The bot has its own account and processes challenges independently.
Its background service needs this host to stay awake and online.

## Mechanics to exercise

- Follow the visible connections on all four layouts. Each connection costs one step;
  diagonal connections count once, and touching squares without a connection are not adjacent.
- Reach the middle square of the opponent's back row to win.
- Surround a piece on every connected neighbor to capture it automatically. Check its
  two-owner-turn cooldown and eventual return to the hand.
- Inspect passive text and active status as pieces move. Energy income includes occupied
  side objectives and on-board Generators, up to a carried balance of five.
- Deploy a Blaster after cycling the initial hand. Announce its row attack with three
  energy. The orange threat markers (dashed rows in 2D) and pending list should appear in your plan; submitting announces
  it without immediate damage. The opponent gets a full turn to respond.
- Move out of a threatened row before ending the response turn. Pieces still in the row,
  including friendly pieces, take four damage subject to shield and damage reduction.
- Announce another delayed ability in response: the newer effect resolves first, and its
  delay holds up older entries. There are no out-of-turn priority prompts.

## Local checks

From the repo root:

```sh
bun install --frozen-lockfile
bun run test
bun run check
bun run --cwd client build
```

From `contracts`, use the project's Scarb 2.13.1 toolchain and run `scarb test`.
The tests cover passive conditions, graph distances, stack timing/order, preview legality,
hand rotation, capture cooldown, goal wins, and bot discovery/retry behavior.

For a stuck bot on this host, inspect `journalctl --user -u caps-bot.service -n 30`.
The active checkpoint is `bot/state/checkpoint-v4.json`; do not replace it with a checkpoint
from the old world. Account keys and bot state remain local and ignored by Git.

## 3D board

The main `/game` route renders the live board with Three.js through Threlte. The old
`/three` demo now redirects to the game. Both views use the same preview, selection,
ability targets, hand, and transaction submission; switching views keeps the current plan.
The camera stays fixed to preserve row orientation and make touch selection predictable.
WebGL initialization failure or context loss switches back to the 2D board automatically.
The view preference is stored locally. The 3D bundle loads separately from the core client.
