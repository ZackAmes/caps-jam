<script lang="ts">
    import { account } from '../stores/account.svelte';
    import { planetelo } from '../stores/planetelo.svelte';
    import { caps } from '../stores/caps.svelte';

    let isOpen = $state(false);
    let inviteAddress = $state('');

    function toggleProfile() {
        isOpen = !isOpen;
    }

    function handleAcceptInvite(inviteId: number) {
        planetelo.accept_invite(inviteId);
    }

    function handleDeclineInvite(inviteId: number) {
        planetelo.decline_invite(inviteId);
    }

    function handleSetCurrentGame(gameId: number) {
        planetelo.set_current_game_id(gameId);
        isOpen = false; // Close profile after selecting game
    }

    async function handleInvitePlayer() {
        if (inviteAddress.trim() && account.account) {
            try {
                const res = await account.account.execute([{
                    contractAddress: planetelo.address,
                    entrypoint: 'invite',
                    calldata: [inviteAddress.trim()]
                }]);
                console.log('Invite sent:', res);
                inviteAddress = ''; // Clear the input
                planetelo.update_status(); // Refresh data
            } catch (error) {
                console.error('Failed to send invite:', error);
            }
        }
    }

    function handleCustomGameAction(game: any) {
        const currentPlayerAddress = account.account?.address;
        
        if (Number(game.game_id) !== 0) {
            // Game has started, load it
            caps.get_game(Number(game.game_id));
            isOpen = false;
        } else if (game.player2 === currentPlayerAddress) {
            // Current player is player2, they can accept the invite
            planetelo.accept_invite(Number(game.id));
        }
        // If player1 and game_id === 0, button is disabled (pending state)
    }

    function getCustomGameButtonText(game: any) {
        const currentPlayerAddress = account.account?.address;
        
        if (Number(game.game_id) !== 0) {
            return 'Play';
        } else if (game.player1 === currentPlayerAddress) {
            return 'Pending';
        } else if (game.player2 === currentPlayerAddress) {
            return 'Accept';
        }
        return 'Play';
    }

    function isCustomGameButtonDisabled(game: any) {
        const currentPlayerAddress = account.account?.address;
        return Number(game.game_id) === 0 && game.player1 === currentPlayerAddress;
    }
</script>

{#if account.account}
    <div class="profile-container">
        <button class="profile-toggle" onclick={toggleProfile}>
            {account.username || 'User'} 
            {#if planetelo.invites.length > 0}
                <span class="notification-badge">{planetelo.invites.length}</span>
            {/if}
        </button>

        {#if isOpen}
            <div class="profile-dropdown">
                <div class="profile-header">
                    <strong>{account.username || 'User'}</strong>
                    <button class="close-button" onclick={toggleProfile}>×</button>
                </div>

                <!-- Invite Section -->
                <div class="section">
                    <h4>Invite Player</h4>
                    <div class="invite-form">
                        <input 
                            type="text" 
                            placeholder="Player address..." 
                            bind:value={inviteAddress}
                            class="invite-input"
                        />
                        <button 
                            class="invite-btn" 
                            onclick={handleInvitePlayer}
                            disabled={!inviteAddress.trim()}
                        >
                            Invite
                        </button>
                    </div>
                </div>

                {#if planetelo.invites.length > 0}
                    <div class="section">
                        <h4>Invites ({planetelo.invites.length})</h4>
                        {#each planetelo.invites as invite}
                            <div class="invite-item">
                                <span>Game #{invite}</span>
                                <div class="invite-actions">
                                    <button class="accept-btn" onclick={() => handleAcceptInvite(invite)}>✓</button>
                                    <button class="decline-btn" onclick={() => handleDeclineInvite(invite)}>×</button>
                                </div>
                            </div>
                        {/each}
                    </div>
                {/if}

                {#if planetelo.custom_games.length > 0}
                    <div class="section">
                        <h4>Custom Games ({planetelo.custom_games.length})</h4>
                        {#each planetelo.custom_games as game}
                            <div class="game-item">
                                <span>Game #{game.id}</span>
                                <button 
                                    class="play-btn" 
                                    class:pending={isCustomGameButtonDisabled(game)}
                                    onclick={() => handleCustomGameAction(game)}
                                    disabled={isCustomGameButtonDisabled(game)}
                                >
                                    {getCustomGameButtonText(game)}
                                </button>
                            </div>
                        {/each}
                    </div>
                {/if}

                {#if planetelo.invites.length === 0 && planetelo.custom_games.length === 0}
                    <div class="empty-state">
                        <p>No invites or custom games</p>
                    </div>
                {/if}
            </div>
        {/if}
    </div>
{/if}

<style>
    .profile-container {
        position: fixed;
        top: 1rem;
        right: 1rem;
        z-index: 100;
    }

    .profile-toggle {
        background: white;
        border: 2px solid #333;
        border-radius: 4px;
        padding: 8px 12px;
        cursor: pointer;
        font-size: 14px;
        font-weight: 500;
        position: relative;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .profile-toggle:hover {
        background: #f5f5f5;
    }

    .notification-badge {
        background: #ef4444;
        color: white;
        border-radius: 50%;
        width: 20px;
        height: 20px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
        font-weight: bold;
    }

    .profile-dropdown {
        position: absolute;
        top: 100%;
        right: 0;
        margin-top: 4px;
        background: white;
        border: 2px solid #333;
        border-radius: 4px;
        min-width: 280px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        font-family: Arial, sans-serif;
    }

    .profile-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 12px;
        border-bottom: 1px solid #ddd;
        background: #f8f9fa;
    }

    .close-button {
        background: none;
        border: none;
        font-size: 18px;
        cursor: pointer;
        color: #666;
        padding: 0;
        width: 20px;
        height: 20px;
    }

    .close-button:hover {
        color: #333;
    }

    .section {
        padding: 12px;
        border-bottom: 1px solid #eee;
    }

    .section:last-child {
        border-bottom: none;
    }

    .section h4 {
        margin: 0 0 8px 0;
        color: #333;
        font-size: 14px;
    }

    .invite-form {
        display: flex;
        gap: 8px;
        align-items: center;
    }

    .invite-input {
        flex: 1;
        padding: 6px 8px;
        border: 1px solid #ddd;
        border-radius: 3px;
        font-size: 12px;
    }

    .invite-input:focus {
        outline: none;
        border-color: #3b82f6;
    }

    .invite-btn {
        background: #8b5cf6;
        color: white;
        border: none;
        border-radius: 3px;
        cursor: pointer;
        font-size: 12px;
        padding: 6px 12px;
        font-weight: 500;
    }

    .invite-btn:hover:not(:disabled) {
        background: #7c3aed;
    }

    .invite-btn:disabled {
        background: #d1d5db;
        cursor: not-allowed;
    }

    .invite-item, .game-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 6px 0;
        font-size: 13px;
    }

    .invite-actions {
        display: flex;
        gap: 4px;
    }

    .accept-btn, .decline-btn, .play-btn {
        border: none;
        border-radius: 3px;
        cursor: pointer;
        font-size: 12px;
        padding: 4px 8px;
        font-weight: 500;
    }

    .accept-btn {
        background: #22c55e;
        color: white;
    }

    .accept-btn:hover {
        background: #16a34a;
    }

    .decline-btn {
        background: #ef4444;
        color: white;
    }

    .decline-btn:hover {
        background: #dc2626;
    }

    .play-btn {
        background: #3b82f6;
        color: white;
    }

    .play-btn:hover:not(:disabled) {
        background: #2563eb;
    }

    .play-btn.pending {
        background: #6b7280;
        cursor: not-allowed;
    }

    .play-btn:disabled {
        cursor: not-allowed;
    }

    .empty-state {
        padding: 12px;
        text-align: center;
        color: #666;
        font-size: 13px;
    }

    .empty-state p {
        margin: 0;
    }
</style> 