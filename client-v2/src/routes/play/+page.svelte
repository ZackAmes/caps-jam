<script lang="ts">
    import { onMount } from 'svelte';
    import { Canvas } from '@threlte/core';
    import { T } from '@threlte/core';
    import { OrbitControls } from '@threlte/extras';
    import GameBoard from '$lib/game/GameBoard.svelte';
    import HandBar from '$lib/game/HandBar.svelte';
    import { createMockGameState } from '$lib/game/gameState';

    let gameState = $state(createMockGameState());
    let selectedPiece = $state<{ id: number; x: number; y: number } | null>(null);
    let selectedHandPiece = $state<number | null>(null);
    let pendingAction = $state<'move' | 'attack' | 'ability' | 'retreat' | null>(null);

    function handleTileClick(x: number, y: number) {
        // If we have a selected hand piece, play it
        if (selectedHandPiece !== null) {
            playPiece(selectedHandPiece, x, y);
            selectedHandPiece = null;
            return;
        }

        // If we have a pending action, execute it
        if (pendingAction && selectedPiece) {
            executeAction(pendingAction, x, y);
            pendingAction = null;
            selectedPiece = null;
            return;
        }

        // Otherwise, select the piece on this tile
        const piece = gameState.boardPieces.find(p => p.x === x && p.y === y);
        if (piece) {
            selectedPiece = { id: piece.id, x: piece.x, y: piece.y };
            selectedHandPiece = null;
        } else {
            selectedPiece = null;
        }
    }

    function playPiece(handIndex: number, x: number, y: number) {
        const piece = gameState.hand[handIndex];
        if (!piece) return;

        // Check if tile is empty
        const existingPiece = gameState.boardPieces.find(p => p.x === x && p.y === y);
        if (existingPiece) return;

        // Remove from hand and add to board
        gameState.hand.splice(handIndex, 1);
        gameState.boardPieces.push({
            id: piece.id,
            x,
            y,
            owner: 'player1',
            type: piece.type,
            health: piece.health,
            maxHealth: piece.maxHealth,
            attack: piece.attack,
            canMove: true,
            canAttack: true,
            canUseAbility: true
        });

        // Add a new piece to hand (mock)
        gameState.hand.push({
            id: Date.now(),
            type: Math.floor(Math.random() * 4),
            health: 10,
            maxHealth: 10,
            attack: 3,
            cost: 2
        });
    }

    function executeAction(action: 'move' | 'attack' | 'ability' | 'retreat', x: number, y: number) {
        if (!selectedPiece) return;

        const piece = gameState.boardPieces.find(p => p.id === selectedPiece!.id);
        if (!piece) return;

        if (action === 'move') {
            const existingPiece = gameState.boardPieces.find(p => p.x === x && p.y === y);
            if (existingPiece) return;
            piece.x = x;
            piece.y = y;
            piece.canMove = false;
        } else if (action === 'attack') {
            const target = gameState.boardPieces.find(p => p.x === x && p.y === y && p.owner !== piece.owner);
            if (target) {
                target.health -= piece.attack;
                if (target.health <= 0) {
                    const index = gameState.boardPieces.indexOf(target);
                    gameState.boardPieces.splice(index, 1);
                }
                piece.canAttack = false;
            }
        } else if (action === 'ability') {
            // Mock ability - heal self
            piece.health = Math.min(piece.health + 2, piece.maxHealth);
            piece.canUseAbility = false;
        } else if (action === 'retreat') {
            // Return piece to hand
            const index = gameState.boardPieces.indexOf(piece);
            gameState.boardPieces.splice(index, 1);
            gameState.hand.push({
                id: piece.id,
                type: piece.type,
                health: piece.health,
                maxHealth: piece.maxHealth,
                attack: piece.attack,
                cost: 2
            });
        }
    }

    function handleActionClick(action: 'move' | 'attack' | 'ability' | 'retreat') {
        if (!selectedPiece) return;
        pendingAction = action;
    }

    function handleHandPieceClick(index: number) {
        selectedHandPiece = index;
        selectedPiece = null;
        pendingAction = null;
    }

    function cancelSelection() {
        selectedPiece = null;
        selectedHandPiece = null;
        pendingAction = null;
    }
</script>

<div class="game-container">
    <div class="game-board-container">
        <Canvas>
            <T.PerspectiveCamera makeDefault position={[0, 8, 6]} fov={60}>
                <OrbitControls enablePan={false} enableZoom={true} enableRotate={true} />
            </T.PerspectiveCamera>
            
            <T.AmbientLight intensity={0.6} />
            <T.DirectionalLight position={[5, 10, 5]} intensity={0.8} />

            <GameBoard 
                boardPieces={gameState.boardPieces}
                selectedPiece={selectedPiece}
                onTileClick={handleTileClick}
                pendingAction={pendingAction}
            />
        </Canvas>
    </div>

</div>

<style>
    .game-container {
        width: 100vw;
        height: 100vh;
        display: flex;
        flex-direction: column;
        background: #f5f5f5;
        overflow: hidden;
    }

    .game-board-container {
        flex: 1;
        position: relative;
        min-height: 0;
    }

    :global(canvas) {
        display: block;
        width: 100%;
        height: 100%;
    }
</style>

