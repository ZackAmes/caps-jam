<script lang="ts">
  import { T } from "@threlte/core";
  import type { Cap } from "../dojo/models.gen";
    import { caps } from "../stores/caps.svelte";

  interface Props {
    cap: Cap;
    position: { x: number; y: number };
  }

  let { cap, position }: Props = $props();

  // Get darker shade of base color (different from target indicators)
  const getBaseColor = (capTypeId: number) => {
    let color_id = capTypeId % 4;
    if (color_id == 0) {
      return "darkred";
    } else if (color_id == 1) {
      return "darkblue";
    } else if (color_id == 2) {
      return "yellow";
    } else if (color_id == 3) {
      return "darkgreen";
    }
  };

  // Get border color based on player
  let accentColor = $derived(cap.owner === caps.game_state?.game.player1 ? "white" : "black");

  let baseColor = $derived(getBaseColor(Number(cap.cap_type)));
</script>

<!-- Match the original cap positioning exactly -->
<T.Group position={[position.x, position.y, 0]}>
  {#if Math.floor(Number(cap.cap_type) / 4) == 0}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={0.2}>
      <T.BoxGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
    <!-- Accent -->
    <T.Mesh scale={0.205}>
      <T.BoxGeometry />
      <T.MeshBasicMaterial color={accentColor} wireframe={true} />
    </T.Mesh>
  {:else if Math.floor(Number(cap.cap_type) / 4) == 1}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={0.2}>
      <T.SphereGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
    <!-- Accent -->
    <T.Mesh scale={0.205}>
      <T.SphereGeometry />
      <T.MeshBasicMaterial color={accentColor} wireframe={true} />
    </T.Mesh>
  {:else if Math.floor(Number(cap.cap_type) / 4) == 2}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={0.2}>
      <T.ConeGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
    <!-- Accent -->
    <T.Mesh scale={0.205}>
      <T.ConeGeometry />
      <T.MeshBasicMaterial color={accentColor} wireframe={true} />
    </T.Mesh>
  {:else if Math.floor(Number(cap.cap_type) / 4) == 3}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={0.2}>
      <T.CylinderGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
    <!-- Accent -->
    <T.Mesh scale={0.205}>
      <T.CylinderGeometry />
      <T.MeshBasicMaterial color={accentColor} wireframe={true} />
    </T.Mesh>
  {:else if Math.floor(Number(cap.cap_type) / 4) == 4}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={0.2}>
      <T.TorusGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
    <!-- Accent -->
    <T.Mesh scale={0.205}>
      <T.TorusGeometry />
      <T.MeshBasicMaterial color={accentColor} wireframe={true} />
    </T.Mesh>
  {:else if Math.floor(Number(cap.cap_type) / 4) == 5}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={0.2}>
      <T.DodecahedronGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
    <!-- Accent -->
    <T.Mesh scale={0.205}>
      <T.DodecahedronGeometry />
      <T.MeshBasicMaterial color={accentColor} wireframe={true} />
    </T.Mesh>
  {:else}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={0.2}>
      <T.OctahedronGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
    <!-- Accent -->
    <T.Mesh scale={0.205}>
      <T.OctahedronGeometry />
      <T.MeshBasicMaterial color={accentColor} wireframe={true} />
    </T.Mesh>
  {/if}
</T.Group>

