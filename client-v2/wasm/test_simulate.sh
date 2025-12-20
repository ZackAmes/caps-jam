#!/bin/bash
cd "$(dirname "$0")"
source ~/cairo-vm/cairo-vm-env/bin/activate

# Test the simulate function with sample input
# Arguments format:
# Game: id, player1, player2, caps_ids[], turn_count, over, effect_ids[], last_action_timestamp
# Caps: array of cap structs
# Effects: array (empty)
# Actions: array of action structs

echo "Testing simulate.cairo with cairo1-run..."

# Using cairo1-run which supports passing arguments
~/cairo-vm/target/release/cairo1-run \
  cairo/simulate.sierra \
  --args '[1, 111, 222, [1 2], 0, 0, [], 0, [1 111 5 3 0 0 4 0 0, 2 222 5 3 6 0 5 0 0], [], [1 5 0 1]]' \
  --print_output \
  --layout all_cairo \
  2>&1

