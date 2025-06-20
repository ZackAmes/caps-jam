<script lang="ts">
  import { account } from "./account.svelte";
  import { planetelo } from "./planetelo.svelte";
  import { T, Canvas } from "@threlte/core";
  import { interactivity } from "@threlte/extras";
  import { useThrelte } from "@threlte/core";

  interactivity();

  let { camera } = useThrelte()

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
      console.log($camera);
  }}>
    <T.BoxGeometry args={[1, 1, .1]} />
    <T.MeshBasicMaterial color={(position.x % 2 == 0 && position.y % 2 == 0) || (position.x % 2 == 1 && position.y % 2 == 1) ? "red" : "blue"} />
  </T.Mesh>
{/each}