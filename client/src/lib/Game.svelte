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

  const get_color = (position: {x: number, y: number}) => {
    // Check if this position is selected
    if (position.x == caps.selected_cap?.position.x && position.y == caps.selected_cap?.position.y) {
      return "yellow";
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
    return (position.x % 2 == 0 && position.y % 2 == 0) || (position.x % 2 == 1 && position.y % 2 == 1) ? "black" : "grey";
  }

  for (let i = 0; i < 7; i++) {
    for (let j = 0; j < 7; j++) {
      positions.push({x: i, y: j})
    }
  }

  $effect(() => {
  })
</script>

{#each positions as position}
  {@const color = get_color(position)}
    <T.Mesh position={[position.x, position.y, 0]} onclick={(e: MouseEvent) => {
      caps.handle_click(position, e)
  }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={color} />
  </T.Mesh>
  {#if caps.game_state && caps.get_cap_at(position.x, position.y)}
    {@const cap = caps.get_cap_at(position.x, position.y)!}
    <CapModel {cap} {position} />
  {/if}
{/each}