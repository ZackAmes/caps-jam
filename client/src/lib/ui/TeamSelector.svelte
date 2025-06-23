<script lang="ts">
    import { caps } from '../stores/caps.svelte';
    import { teamColors, teams } from '../utils/colors';

    let showTeams = $state(false);

    function selectTeam(teamId: number) {
        caps.select_team(teamId);
        showTeams = false;
    }
</script>

<div class="team-selector">
    <button
        class="current-team"
        style:background-color={teamColors[caps.selected_team ?? 0]}
        onclick={() => (showTeams = !showTeams)}
    >
        Team
    </button>
    {#if showTeams}
        <div class="team-options">
            {#each teams as teamId}
                <button
                    class="team-option"
                    style:background-color={teamColors[teamId]}
                    onclick={() => selectTeam(teamId)}
                    aria-label="Select team {teamId}"
                />
            {/each}
        </div>
    {/if}
</div>

<style>
    .team-selector {
        position: relative;
        display: inline-block;
    }
    .current-team {
        color: white;
        text-shadow: 0 0 3px black;
    }
    .team-options {
        position: absolute;
        top: 100%;
        left: 50%;
        transform: translateX(-50%);
        display: flex;
        gap: 5px;
        background-color: #242424;
        border: 1px solid #666;
        border-radius: 8px;
        padding: 8px;
        margin-top: 4px;
        z-index: 10;
    }
    .team-option {
        width: 30px;
        height: 30px;
        border: 1px solid #666;
        border-radius: 50%;
        padding: 0;
        cursor: pointer;
    }
    .team-option:hover {
        border-color: #aaa;
    }
</style> 