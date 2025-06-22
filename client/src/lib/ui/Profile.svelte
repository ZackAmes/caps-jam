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
                    <div class="header-buttons">
                        <button class="disconnect-btn" onclick={account.disconnect}>Disconnect</button>
                        <button class="close-button" onclick={toggleProfile}>×</button>
                    </div>
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
        margin: 1rem auto;
        max-width: 600px;
        position: relative;
        text-align: center;
    }

    /* Mobile responsive profile positioning */
    @media (max-width: 768px) {
        .profile-container {
            margin: 0.5rem auto;
        }
    }

    .profile-toggle {
        background: #f8f9fa;
        border: 2px solid #333;
        border-radius: 8px;
        padding: 12px 20px;
        cursor: pointer;
        font-size: 16px;
        font-weight: 600;
        position: relative;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        color: #333;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        transition: all 0.2s ease;
    }

    @media (max-width: 768px) {
        .profile-toggle {
            padding: 16px 24px;
            font-size: 18px;
            border-radius: 8px;
            min-height: 56px; /* Touch-friendly */
        }
    }

    .profile-toggle:hover {
        background: #e9ecef;
        transform: translateY(-1px);
        box-shadow: 0 4px 8px rgba(0,0,0,0.15);
    }

    .notification-badge {
        background: #ef4444;
        color: white;
        border-radius: 50%;
        width: 24px;
        height: 24px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
        font-weight: bold;
        box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }

    @media (max-width: 768px) {
        .notification-badge {
            width: 28px;
            height: 28px;
            font-size: 14px;
        }
    }

    .profile-dropdown {
        position: absolute;
        top: 100%;
        left: 50%;
        transform: translateX(-50%);
        margin-top: 8px;
        background: white;
        border: 2px solid #333;
        border-radius: 8px;
        padding: 0;
        min-width: 320px;
        max-width: 450px;
        box-shadow: 0 8px 24px rgba(0,0,0,0.15);
        font-size: 14px;
        z-index: 100;
    }

    @media (max-width: 768px) {
        .profile-dropdown {
            position: static;
            transform: none;
            margin-top: 12px;
            width: 100%;
            min-width: auto;
            max-width: none;
            padding: 0;
            font-size: 16px;
            border-radius: 8px;
            max-height: none;
            overflow-y: visible;
        }
    }

    .profile-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 16px;
        border-bottom: 2px solid #e9ecef;
        background: #f8f9fa;
        border-radius: 6px 6px 0 0;
    }

    .profile-header strong {
        color: #212529;
        font-size: 18px;
        font-weight: 700;
    }

    @media (max-width: 768px) {
        .profile-header strong {
            font-size: 20px;
        }
    }

    .header-buttons {
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .disconnect-btn {
        background: #ef4444;
        color: white;
        border: none;
        border-radius: 4px;
        padding: 6px 12px;
        cursor: pointer;
        font-size: 12px;
        font-weight: 500;
    }

    .disconnect-btn:hover {
        background: #dc2626;
    }

    @media (max-width: 768px) {
        .disconnect-btn {
            padding: 8px 16px;
            font-size: 14px;
        }
    }

    .close-button {
        background: none;
        border: none;
        font-size: 18px;
        cursor: pointer;
        color: #666;
        padding: 4px;
        width: 24px;
        height: 24px;
        border-radius: 2px;
    }

    @media (max-width: 768px) {
        .close-button {
            font-size: 24px;
            width: 32px;
            height: 32px;
            padding: 8px;
        }
    }

    .close-button:hover {
        background: #f5f5f5;
        color: #333;
    }

    .section {
        margin-bottom: 16px;
        padding: 16px;
        background: #ffffff;
    }

    .section:last-child {
        margin-bottom: 0;
    }

    @media (max-width: 768px) {
        .section {
            margin-bottom: 20px;
            padding: 20px;
        }
    }

    .section h4 {
        margin: 0 0 12px 0;
        color: #212529;
        font-size: 16px;
        font-weight: 700;
        letter-spacing: 0.025em;
    }

    @media (max-width: 768px) {
        .section h4 {
            font-size: 18px;
            margin-bottom: 16px;
        }
    }

    .invite-form {
        display: flex;
        gap: 8px;
        margin-top: 6px;
    }

    @media (max-width: 768px) {
        .invite-form {
            flex-direction: column;
            gap: 12px;
        }
    }

    .invite-input {
        flex: 1;
        padding: 6px 8px;
        border: 1px solid #ccc;
        border-radius: 3px;
        font-size: 14px;
    }

    @media (max-width: 768px) {
        .invite-input {
            padding: 12px 16px;
            font-size: 16px;
            border-radius: 6px;
            min-height: 48px;
        }
    }

    .invite-btn {
        padding: 6px 12px;
        background: #3b82f6;
        color: white;
        border: none;
        border-radius: 3px;
        cursor: pointer;
        font-size: 14px;
        font-weight: 500;
    }

    @media (max-width: 768px) {
        .invite-btn {
            padding: 12px 16px;
            font-size: 16px;
            border-radius: 6px;
            min-height: 48px;
        }
    }

    .invite-btn:hover:not(:disabled) {
        background: #2563eb;
    }

    .invite-btn:disabled {
        background: #9ca3af;
        cursor: not-allowed;
    }

    .invite-item, .game-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px;
        margin: 4px 0;
        background: #f8f9fa;
        border-radius: 4px;
        font-size: 13px;
    }

    @media (max-width: 768px) {
        .invite-item, .game-item {
            padding: 12px;
            margin: 8px 0;
            border-radius: 6px;
            font-size: 16px;
        }
    }

    .invite-actions {
        display: flex;
        gap: 4px;
    }

    @media (max-width: 768px) {
        .invite-actions {
            gap: 8px;
        }
    }

    .accept-btn, .decline-btn, .play-btn {
        padding: 4px 8px;
        border: none;
        border-radius: 3px;
        cursor: pointer;
        font-size: 12px;
        font-weight: 500;
    }

    @media (max-width: 768px) {
        .accept-btn, .decline-btn, .play-btn {
            padding: 8px 12px;
            font-size: 14px;
            border-radius: 4px;
            min-height: 40px;
            min-width: 40px;
        }
    }

    .accept-btn {
        background: #10b981;
        color: white;
    }

    .accept-btn:hover {
        background: #059669;
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
        background: #9ca3af;
        cursor: not-allowed;
    }

    .empty-state {
        padding: 20px;
        text-align: center;
        color: #666;
        font-style: italic;
    }

    @media (max-width: 768px) {
        .empty-state {
            padding: 24px;
            font-size: 16px;
        }
    }
</style> 