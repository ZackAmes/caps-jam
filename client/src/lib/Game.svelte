<script lang="ts">
  import { account } from "./account.svelte";
  import { planetelo } from "./planetelo.svelte";
  import { T, Canvas } from "@threlte/core";
  import { interactivity } from "@threlte/extras";

  interactivity();

  let positions = []

  for (let i = 0; i < 7; i++) {
    for (let j = 0; j < 7; j++) {
      positions.push({x: i, y: j})
    }
  }
</script>

  <T.PerspectiveCamera
  position={[0, 0, 20]}
  oncreate={(ref) => {
    ref.lookAt(0, 0, 0)
  }}
/>

{#each positions as position}
  <T.Mesh position={[position.x, position.y, 0]} onclick={() => {
    console.log(position)
  }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={(position.x % 2 == 0 && position.y % 2 == 0) || (position.x % 2 == 1 && position.y % 2 == 1) ? "red" : "blue"} />
  </T.Mesh>
{/each}