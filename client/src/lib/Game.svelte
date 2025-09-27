<script lang="ts">
  import { account } from "./stores/account.svelte";
  import { planetelo } from "./stores/planetelo.svelte";
  import { T, Canvas } from "@threlte/core";
  import { interactivity } from "@threlte/extras";
  import { useThrelte } from "@threlte/core";
  import { caps } from "./stores/caps.svelte";
  import type { Cap, ActionType } from "./dojo/models.gen";
  import { CairoCustomEnum } from "starknet";
  import CapModel from "./3d/cap.svelte";
  interactivity();

  let { camera } = useThrelte()

  camera.update(camera => {
    // Position camera to see both player benches and the board
    // Board: (0-6), Player1 bench: y=-1, Player2 bench: y=7
    // Center view around y=3 to see from -1 to 7, with small gaps between board and benches
    camera.position.set(3, 3, 6)
    // Look at the center point between both benches and board
    camera.lookAt(3, 3, 0)
    return camera
  })

  let positions = []
  
  // Create bench positions - tentacles would approve of organized storage! 🐙
  // Player 1 bench (bottom) - white pieces, with small gap from board
  let player1_bench_positions = []
  for (let i = 0; i < 5; i++) {
    player1_bench_positions.push({x: i + 1, y: -1.2, player: 'player1'}) // Centered (x=1-5), small gap from board
  }
  
  // Player 2 bench (top) - black pieces, with small gap from board
  let player2_bench_positions = []
  for (let i = 0; i < 5; i++) {
    player2_bench_positions.push({x: i + 1, y: 7.2, player: 'player2'}) // Centered (x=1-5), small gap from board
  }

  const get_selected_cap_location = () => {
    if (!caps.selected_cap) return null;
    const location_variant = caps.selected_cap.location.activeVariant();
    return location_variant;
  }

  const get_color = (position: {x: number, y: number}) => {
    // Check if this position is selected based on location
    const selected_location = get_selected_cap_location();
    if (selected_location === 'Board') {
      const board_position = caps.selected_cap?.location.unwrap();
      if (board_position && position.x == board_position.x && position.y == board_position.y) {
        return "yellow";
      }
    }
    
    // Check which valid target arrays this position is in
    const isValidMove = caps.valid_moves?.some(move => move.x === position.x && move.y === position.y) || false;
    const isValidAbility = caps.valid_ability_targets?.some(target => target.x === position.x && target.y === position.y) || false;
    const isValidAttack = caps.valid_attacks?.some(attack => attack.x === position.x && attack.y === position.y) || false;
    
    // Count how many states apply
    const states = [isValidMove, isValidAbility, isValidAttack].filter(Boolean);
    
    if (states.length > 1) {
      // Multiple states - for now return a mixed color
      // TODO: Implement actual striping with custom materials/shaders
      if (isValidMove && isValidAbility && isValidAttack) {
        return "purple"; // Mix of all three
      } else if (isValidMove && isValidAbility) {
        return "cyan"; // Mix of green and blue
      } else if (isValidMove && isValidAttack) {
        return "orange"; // Mix of green and red
      } else if (isValidAbility && isValidAttack) {
        return "magenta"; // Mix of blue and red
      }
    } else {
      // Single state
      if (isValidMove) return "green";
      if (isValidAbility) return "blue";
      if (isValidAttack) return "red";
    }
    
    // Default checkerboard pattern (black and grey instead of red and blue)
    return (position.x % 2 == 0 && position.y % 2 == 0) || (position.x % 2 == 1 && position.y % 2 == 1) ? "#222222" : "#333333";
  }

  const get_bench_color = (player: string) => {
    // Bench squares are colored by player - where tentacles rest between battles! 🐙
    if (player === 'player1') {
      return "#333333"; // Darker for player1 (white pieces)
    } else {
      return "#666666"; // Lighter for player2 (black pieces) 
    }
  }

  for (let i = 0; i < 7; i++) {
    for (let j = 0; j < 7; j++) {
      positions.push({x: i, y: j})
    }
  }

  // Helper to get all caps with their locations
  const get_all_caps = () => {
    return caps.game_state?.caps || [];
  }

  // Helper to get caps on the board at specific position
  const get_cap_at_board_position = (x: number, y: number): Cap | undefined => {
    return get_all_caps().find(cap => {
      const location_variant = cap.location.activeVariant();
      if (location_variant === 'Board') {
        const board_position = cap.location.unwrap();
        return board_position.x == x && board_position.y == y;
      }
      return false;
    });
  }

  // Helper to get caps on the bench for specific player
  const get_player_bench_caps = (player_address: string) => {
    return get_all_caps().filter(cap => {
      const location_variant = cap.location.activeVariant();
      return location_variant === 'Bench' && cap.owner === player_address;
    });
  }
  
  // Helper to get player1's bench caps
  const get_player1_bench_caps = () => {
    return get_player_bench_caps(caps.game_state?.game.player1 || '');
  }
  
  // Helper to get player2's bench caps  
  const get_player2_bench_caps = () => {
    return get_player_bench_caps(caps.game_state?.game.player2 || '');
  }

  $effect(() => {
  })
</script>

<!-- Board squares -->
{#each positions as position}
  {@const color = get_color(position)}
    <T.Mesh position={[position.x, position.y, 0]} onclick={(e) => {
      caps.handle_click(position, e)
    }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={color} />
  </T.Mesh>
  {#if caps.game_state && get_cap_at_board_position(position.x, position.y)}
    {@const cap = get_cap_at_board_position(position.x, position.y)!}
    {@const location_variant = cap.location.activeVariant()}
    {#if location_variant === 'Board'}
      {@const board_position = cap.location.unwrap()}
      <CapModel cap={cap} position={{x: Number(board_position.x), y: Number(board_position.y), z: 0.1}!} />
    {/if}
  {/if}
{/each}

<!-- Player 1 Bench squares (bottom) - where tentacles contemplate their next move! 🐙 -->
{#each player1_bench_positions as bench_position, index}
  {@const bench_color = get_bench_color('player1')}
    <T.Mesh position={[bench_position.x, bench_position.y, 0]} onclick={(e) => {
      // TODO: Handle bench clicks for playing pieces from bench
      console.log('Clicked Player 1 bench position:', bench_position)
    }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={bench_color} />
  </T.Mesh>
{/each}

<!-- Player 2 Bench squares (top) -->
{#each player2_bench_positions as bench_position, index}
  {@const bench_color = get_bench_color('player2')}
    <T.Mesh position={[bench_position.x, bench_position.y, 0]} onclick={(e) => {
      // TODO: Handle bench clicks for playing pieces from bench
      console.log('Clicked Player 2 bench position:', bench_position)
    }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={bench_color} />
  </T.Mesh>
{/each}

<!-- Player 1 Bench caps (bottom) -->
{#if caps.game_state}
  {@const player1_bench_caps = get_player1_bench_caps()}
  {#each player1_bench_caps as cap, index}
    {@const bench_position = {x: index + 1, y: -1.1, z: 0.1}}
    <CapModel cap={cap} position={bench_position} />
  {/each}
{/if}

<!-- Player 2 Bench caps (top) -->
{#if caps.game_state}
  {@const player2_bench_caps = get_player2_bench_caps()}
  {#each player2_bench_caps as cap, index}
    {@const bench_position = {x: index + 1, y: 7.1, z: 0.1}}
    <CapModel cap={cap} position={bench_position} />
  {/each}
{/if}