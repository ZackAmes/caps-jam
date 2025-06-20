<script lang="ts">
  import { account } from "./account.svelte";
  import { planetelo } from "./planetelo.svelte";
  import { T, Canvas } from "@threlte/core";
  import { interactivity } from "@threlte/extras";
  import { useThrelte } from "@threlte/core";
  import { caps } from "./caps.svelte";
  import type { Cap } from "./bindings/models.gen";

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
    <T.Mesh position={[position.x, position.y, 0]} onclick={() => {
      let cap = caps.get_cap_at(position.x, position.y)
      if (selected_cap && cap?.id != selected_cap.id && cap?.owner != account.account?.address) {
        caps.take_turn(selected_cap.position.x.toString(), selected_cap.position.y.toString())
        selected_cap = null
      }
      if (cap && cap.owner == account.account?.address) {
        console.log(cap)
        selected_cap = cap
      }
  }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={(position.x % 2 == 0 && position.y % 2 == 0) || (position.x % 2 == 1 && position.y % 2 == 1) ? "red" : "blue"} />
  </T.Mesh>
  {#if caps.game_state && caps.get_cap_at(position.x, position.y)}
    <T.Mesh position={[position.x, position.y, 0]}>
      <T.BoxGeometry args={[.3, .3, .1]} />
      <T.MeshBasicMaterial color="green" />
    </T.Mesh>
  {/if}
{/each}