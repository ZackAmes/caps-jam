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
    camera.position.set(3, 3, 5)
    return camera
  })

  let positions = []
  
  // Create bench positions - tentacles would approve of organized storage! 🐙
  let bench_positions = []
  for (let i = 0; i < 10; i++) {
    bench_positions.push({x: i - 2, y: -2}) // Bench below the board
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

  const get_bench_color = (index: number) => {
    // Bench squares are a darker color - where tentacles rest between battles! 🐙
    return "#444444";
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

  // Helper to get caps on the bench
  const get_bench_caps = () => {
    return get_all_caps().filter(cap => {
      const location_variant = cap.location.activeVariant();
      return location_variant === 'Bench';
    });
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
      <CapModel cap={cap!} position={{x: Number(board_position.x), y: Number(board_position.y)}!} />
    {/if}
  {/if}
{/each}

<!-- Bench squares - where tentacles contemplate their next move! 🐙 -->
{#each bench_positions as bench_position, index}
  {@const bench_color = get_bench_color(index)}
    <T.Mesh position={[bench_position.x, bench_position.y, 0]} onclick={(e) => {
      // TODO: Handle bench clicks for playing pieces from bench
      console.log('Clicked bench position:', bench_position)
    }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={bench_color} />
  </T.Mesh>
{/each}

<!-- Bench caps -->
{#if caps.game_state}
  {@const bench_caps = get_bench_caps()}
  {#each bench_caps as cap, index}
    {@const bench_position = {x: index - 2, y: -2}}
    <CapModel cap={cap} position={bench_position} />
  {/each}
{/if}