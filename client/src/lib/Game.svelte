<script lang="ts">
  import { account } from "./stores/account.svelte";
  import { planetelo } from "./stores/planetelo.svelte";
  import { T, Canvas } from "@threlte/core";
  import { interactivity } from "@threlte/extras";
  import { useThrelte } from "@threlte/core";
  import { caps } from "./stores/caps.svelte";
  import type { Cap, ActionType } from "./dojo/models.gen";
  import { CairoCustomEnum } from "starknet";
  interactivity();

  let { camera } = useThrelte()

  let selected_cap = $state<Cap | null>(null)

  camera.update(camera => {
    camera.position.set(3, 3, 5)
    return camera
  })

  let positions = []

  for (let i = 0; i < 7; i++) {
    for (let j = 0; j < 7; j++) {
      positions.push({x: i, y: j})
    }
  }
</script>

{#each positions as position}
  {@const color = (position.x == caps.selected_cap?.position.x && position.y == caps.selected_cap?.position.y) ? "yellow" : (position.x % 2 == 0 && position.y % 2 == 0) || (position.x % 2 == 1 && position.y % 2 == 1) ? "red" : "blue"}
    <T.Mesh position={[position.x, position.y, 0]} onclick={() => {
      caps.handle_click(position)
  }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={color} />
  </T.Mesh>
  {#if caps.game_state && caps.get_cap_at(position.x, position.y)}
    <T.Mesh position={[position.x, position.y, 0]}>
      <T.BoxGeometry args={[.3, .3, .1]} />
      <T.MeshBasicMaterial color="green" />
    </T.Mesh>
  {/if}
{/each}