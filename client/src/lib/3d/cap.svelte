<script lang="ts">
  import { T } from "@threlte/core";
  import type { Cap } from "../dojo/models.gen";
    import { caps } from "../stores/caps.svelte";

  interface Props {
    cap: Cap;
    position: { x: number; y: number };
    player: 1 | 2; // Player 1 or Player 2
  }

  let { cap, position, player }: Props = $props();

  // Get darker shade of base color (different from target indicators)
  const getBaseColor = (capTypeId: number) => {
    switch (capTypeId) {
      case 0: return "darkred";    // Red Tower
      case 1: return "darkblue";   // Blue Tower  
      case 2: return "darkred";    // Red Basic
      case 3: return "darkblue";   // Blue Basic
      default: return "gray";
    }
  };

  // Get border color based on player
  let borderColor = $derived(cap.owner === caps.game_state?.game.player1 ? "white" : "black");
  // Get shape type (tower vs basic)
  const isTower = (capTypeId: number) => {
    return capTypeId === 0 || capTypeId === 1;
  };

  let baseColor = $derived(getBaseColor(Number(cap.cap_type)));
  let isCapTower = $derived(isTower(Number(cap.cap_type)));
</script>

<!-- Match the original cap positioning exactly -->
<T.Group position={[position.x, position.y, 0]}>
  {#if cap.cap_type == 0 || cap.cap_type == 1}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={.2}>
      <T.BoxGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>

  {:else if cap.cap_type == 2}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={.2}>
      <T.SphereGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
  {:else if cap.cap_type == 3}

    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={.2}>
      <T.SphereGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
  {/if}
</T.Group>

