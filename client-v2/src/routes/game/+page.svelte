<script lang="ts">
    import { onMount } from 'svelte';
    import { Canvas } from '@threlte/core';
    import { T } from '@threlte/core';
    import { OrbitControls } from '@threlte/extras';
    import { Contract } from 'starknet';
    import manifest from '../../../../contracts/manifest_sepolia.json';
    import { type Abi } from 'starknet';
    let contract = new Contract({abi: manifest.contracts[0].abi, address: manifest.contracts[0].address}).typedv2(manifest.contracts[0].abi as Abi);
    import type { Game, Cap, Effect } from '$lib/types/models';

    let { gameId }: { gameId: number } = $props();
    
    let game = $state<{game: Game, caps: Array<Cap>, effects: Array<Effect>} | null>(null);

    onMount(async () => {
        game = await contract.getGame(gameId);
    });
</script>

<Canvas>
    <T.PerspectiveCamera makeDefault position={[8, 8, 8]} fov={50}>
        <OrbitControls />
    </T.PerspectiveCamera>
</Canvas>