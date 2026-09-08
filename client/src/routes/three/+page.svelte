<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    onMount(() => { goto(`/game${location.search}`, { replaceState: true }); });
</script>
<p>Opening the playable 3D board… <a href="/game">Continue to game</a></p>
