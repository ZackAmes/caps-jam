<script lang="ts">
  import { T } from "@threlte/core";
  import type { Cap } from "../dojo/models.gen";
  import { caps } from "../stores/caps.svelte";
  import { getBaseColor } from "../utils/colors";

  interface Props {
    cap: Cap;
    position: { x: number; y: number };
  }

  let { cap, position }: Props = $props();

  // Get border color based on player
  let accentColor = $derived(cap.owner === caps.game_state?.game.player1 ? "white" : "black");

  let baseColor = $derived(getBaseColor(Number(cap.cap_type)));
</script>

<!-- Match the original cap positioning exactly -->
<T.Group position={[position.x, position.y, 0]}>
  {#if Math.floor(Number(cap.cap_type) / 4) == 0}
    <!-- Main body -->
    <T.Mesh position={[0, 0, 0.000001]} scale={0.22}>
      <T.BoxGeometry />
      <T.MeshBasicMaterial color={baseColor} />
    </T.Mesh>
    <!-- Wireframe Accent -->
    <T.Mesh scale={0.225}>
      <T.BoxGeometry />
      <T.MeshBasicMaterial color={accentColor} wireframe={true} />
    </T.Mesh>
    <!-- Crown Accent -->
    <T.Mesh position={[0, 0, 0.1]} rotation.z={Math.PI / 2} scale={0.17}>
      <T.TorusGeometry args={[0.5, 0.1]} />
      <T.MeshBasicMaterial color={accentColor} />
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

