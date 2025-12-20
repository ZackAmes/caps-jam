<script lang="ts">
    import { Canvas } from '@threlte/core';
    import { T } from '@threlte/core';
    import { onMount, onDestroy } from 'svelte';
    import { createMockGameState, type BoardPiece, type HandPiece, type GameState } from '$lib/game/gameState';
    import InteractiveBoard from '$lib/game/InteractiveBoard.svelte';
    import HandBar from '$lib/game/HandBar.svelte';

    let gameState = $state<GameState>(createMockGameState());
    let selectedHandIndex = $state<number | null>(null);
    let selectedBoardPiece = $state<BoardPiece | null>(null);
    let pendingAction = $state<'play' | 'move' | 'attack' | 'ability' | 'retreat' | null>(null);
    let actionMenuPosition = $state<{ x: number; y: number } | null>(null);
    
    // Drag state for hand pieces
    let draggingHandPiece = $state<{ index: number; piece: HandPiece; x: number; y: number } | null>(null);

    function getTilePosition(x: number, y: number): [number, number, number] {
        const GRID_WIDTH = 3;
        const GRID_HEIGHT = 7;
        const TILE_SIZE = 1.2;
        const TILE_SPACING = 0.15;
        const offsetX = -(GRID_WIDTH - 1) * (TILE_SIZE + TILE_SPACING) / 2;
        const offsetZ = -(GRID_HEIGHT - 1) * (TILE_SIZE + TILE_SPACING) / 2;
        
        return [
            offsetX + x * (TILE_SIZE + TILE_SPACING),
            0,
            offsetZ + y * (TILE_SIZE + TILE_SPACING)
        ];
    }

    function handleHandPieceClick(index: number) {
        // Only handle click if not dragging
        if (!draggingHandPiece) {
            if (selectedHandIndex === index) {
                selectedHandIndex = null;
                pendingAction = null;
            } else {
                selectedHandIndex = index;
                selectedBoardPiece = null;
                pendingAction = 'play';
            }
        }
    }

    function handleHandPieceDragStart(index: number, piece: HandPiece, event: PointerEvent) {
        if (gameState.energy < piece.cost) return; // Can't afford
        
        draggingHandPiece = {
            index,
            piece,
            x: event.clientX,
            y: event.clientY
        };
        event.preventDefault();
    }


    function handleHandPieceDrop(x: number, y: number) {
        if (!draggingHandPiece) return;
        
        const { index, piece } = draggingHandPiece;
        
        // Check if we can afford it
        if (gameState.energy >= piece.cost) {
            // Check if tile is empty
            const tileEmpty = !gameState.boardPieces.some(p => p.x === x && p.y === y);
            
            if (tileEmpty) {
                const newPiece: BoardPiece = {
                    id: Date.now(),
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
                };
                gameState.boardPieces.push(newPiece);
                gameState.energy -= piece.cost;
                gameState.hand = gameState.hand.filter((_, i) => i !== index);
            }
        }
        
        draggingHandPiece = null;
    }

    function handleTileClick(x: number, y: number) {
        // Check if there's a piece at this position
        const pieceAtPosition = gameState.boardPieces.find(p => p.x === x && p.y === y && p.owner === 'player1');
        
        if (pieceAtPosition) {
            // Select this piece
            if (selectedBoardPiece?.id === pieceAtPosition.id) {
                selectedBoardPiece = null;
                pendingAction = null;
                actionMenuPosition = null;
            } else {
                selectedBoardPiece = pieceAtPosition;
                selectedHandIndex = null;
                pendingAction = null;
                // Calculate position for action menu (will be shown above piece on mobile)
                const [posX, , posZ] = getTilePosition(x, y);
                actionMenuPosition = { x: posX, y: posZ };
            }
        } else if (selectedHandIndex !== null && pendingAction === 'play') {
            // Try to play a piece
            const handPiece = gameState.hand[selectedHandIndex];
            if (handPiece && gameState.energy >= handPiece.cost) {
                const newPiece: BoardPiece = {
                    id: Date.now(),
                    x,
                    y,
                    owner: 'player1',
                    type: handPiece.type,
                    health: handPiece.health,
                    maxHealth: handPiece.maxHealth,
                    attack: handPiece.attack,
                    canMove: true,
                    canAttack: true,
                    canUseAbility: true
                };
                gameState.boardPieces.push(newPiece);
                gameState.energy -= handPiece.cost;
                gameState.hand = gameState.hand.filter((_, i) => i !== selectedHandIndex);
                selectedHandIndex = null;
                pendingAction = null;
            }
            } else if (selectedBoardPiece && pendingAction) {
            // Execute action
            if (pendingAction === 'move') {
                const dx = Math.abs(x - selectedBoardPiece.x);
                const dy = Math.abs(y - selectedBoardPiece.y);
                if ((dx === 1 && dy === 0) || (dx === 0 && dy === 1)) {
                    const piece = gameState.boardPieces.find(p => p.id === selectedBoardPiece!.id);
                    if (piece) {
                        piece.x = x;
                        piece.y = y;
                        piece.canMove = false;
                    }
                    selectedBoardPiece = null;
                    pendingAction = null;
                    actionMenuPosition = null;
                }
            } else if (pendingAction === 'attack') {
                const targetPiece = gameState.boardPieces.find(p => p.x === x && p.y === y && p.owner === 'player2');
                if (targetPiece && selectedBoardPiece) {
                    targetPiece.health -= selectedBoardPiece.attack;
                    if (targetPiece.health <= 0) {
                        gameState.boardPieces = gameState.boardPieces.filter(p => p.id !== targetPiece.id);
                    }
                    const piece = gameState.boardPieces.find(p => p.id === selectedBoardPiece!.id);
                    if (piece) {
                        piece.canAttack = false;
                    }
                    selectedBoardPiece = null;
                    pendingAction = null;
                    actionMenuPosition = null;
                }
            }
        }
    }

    function handleActionClick(action: 'move' | 'attack' | 'ability' | 'retreat') {
        const piece = selectedBoardPiece;
        if (!piece) return;

        if (action === 'retreat') {
            // Remove piece from board
            gameState.boardPieces = gameState.boardPieces.filter(p => p.id !== piece.id);
            selectedBoardPiece = null;
            pendingAction = null;
            actionMenuPosition = null;
        } else {
            pendingAction = action;
        }
    }

    function handlePieceClick(piece: BoardPiece) {
        if (selectedBoardPiece?.id === piece.id) {
            selectedBoardPiece = null;
            pendingAction = null;
            actionMenuPosition = null;
        } else {
            selectedBoardPiece = piece;
            selectedHandIndex = null;
            pendingAction = null;
            const [tileX, , tileZ] = getTilePosition(piece.x, piece.y);
            actionMenuPosition = { x: tileX, y: tileZ };
        }
    }

    // Prevent default touch behaviors and handle drag tracking
    onMount(() => {
        const preventDefault = (e: TouchEvent) => {
            if (e.touches.length > 1) {
                e.preventDefault(); // Prevent pinch zoom
            }
        };

        const preventScroll = (e: TouchEvent) => {
            // Only prevent if we're not dragging a hand piece
            if (!draggingHandPiece) {
                e.preventDefault();
            }
        };

        document.addEventListener('touchmove', preventScroll, { passive: false });
        document.addEventListener('touchstart', preventDefault, { passive: false });
        document.body.style.overflow = 'hidden';
        document.body.style.position = 'fixed';
        document.body.style.width = '100%';
        document.body.style.height = '100%';

        const handlePointerMove = (event: PointerEvent) => {
            if (draggingHandPiece) {
                draggingHandPiece.x = event.clientX;
                draggingHandPiece.y = event.clientY;
            }
        };

        const handlePointerUp = () => {
            if (draggingHandPiece) {
                draggingHandPiece = null;
            }
        };

        window.addEventListener('pointermove', handlePointerMove);
        window.addEventListener('pointerup', handlePointerUp);

        return () => {
            document.removeEventListener('touchmove', preventScroll);
            document.removeEventListener('touchstart', preventDefault);
            window.removeEventListener('pointermove', handlePointerMove);
            window.removeEventListener('pointerup', handlePointerUp);
            document.body.style.overflow = '';
            document.body.style.position = '';
            document.body.style.width = '';
            document.body.style.height = '';
        };
    });
</script>

<div class="game-container">
    <div class="energy-bar">
        <div class="energy-label">Energy</div>
        <div class="energy-value">{gameState.energy} / {gameState.maxEnergy}</div>
        <div class="energy-bar-fill" style="width: {(gameState.energy / gameState.maxEnergy) * 100}%"></div>
    </div>

    <div class="canvas-wrapper">
        <Canvas>
            <T.PerspectiveCamera makeDefault position={[0, 12, 0]} rotation={[-Math.PI / 2, 0, 0]} fov={50} />
            
            <T.AmbientLight intensity={0.6} />
            <T.DirectionalLight position={[5, 10, 5]} intensity={0.8} />

            <InteractiveBoard 
                {gameState}
                {selectedBoardPiece}
                {pendingAction}
                draggingHandPiece={draggingHandPiece}
                onTileClick={handleTileClick}
                onPieceClick={handlePieceClick}
                onTileDrop={handleHandPieceDrop}
                onPieceMove={(pieceId, x, y) => {
                    const piece = gameState.boardPieces.find(p => p.id === pieceId);
                    if (piece && piece.owner === 'player1' && piece.canMove) {
                        piece.x = x;
                        piece.y = y;
                        piece.canMove = false;
                        selectedBoardPiece = null;
                        pendingAction = null;
                        actionMenuPosition = null;
                    }
                }}
            />
        </Canvas>
    </div>

    <!-- Mobile Action Menu (shown when piece is selected) -->
    {#if selectedBoardPiece && actionMenuPosition}
        {@const [posX, , posZ] = getTilePosition(selectedBoardPiece.x, selectedBoardPiece.y)}
        <div class="action-menu" style="--tile-x: {posX}; --tile-z: {posZ};">
            <div class="action-buttons-top">
                {#if selectedBoardPiece?.canMove}
                    <button class="action-btn move-btn" onclick={() => handleActionClick('move')}>
                        Move
                    </button>
                {/if}
            </div>
            <div class="action-buttons-middle">
                {#if selectedBoardPiece?.canUseAbility}
                    <button class="action-btn ability-btn" onclick={() => handleActionClick('ability')}>
                        Ability
                    </button>
                {/if}
                {#if selectedBoardPiece?.canAttack}
                    <button class="action-btn attack-btn" onclick={() => handleActionClick('attack')}>
                        ⚔️ {selectedBoardPiece.attack}
                    </button>
                {/if}
            </div>
            <div class="action-buttons-bottom">
                <button class="action-btn retreat-btn" onclick={() => handleActionClick('retreat')}>
                    Retreat
                </button>
            </div>
        </div>
    {/if}

    <!-- Hand Bar -->
    <HandBar 
        hand={gameState.hand}
        selectedIndex={selectedHandIndex}
        energy={gameState.energy}
        onPieceClick={handleHandPieceClick}
        onPieceDragStart={handleHandPieceDragStart}
    />

    <!-- Drag ghost piece -->
    {#if draggingHandPiece}
        <div 
            class="drag-ghost"
            style="left: {draggingHandPiece.x}px; top: {draggingHandPiece.y}px;"
        >
            <div class="ghost-piece-circle" style="background: {['#ff6b6b', '#4ecdc4', '#ffe66d', '#a8e6cf'][draggingHandPiece.piece.type % 4]}">
                {draggingHandPiece.piece.type + 1}
            </div>
        </div>
    {/if}
</div>


<style>
    :global(html, body) {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
        touch-action: none;
        -webkit-overflow-scrolling: none;
        position: fixed;
    }

    .game-container {
        width: 100vw;
        height: 100vh;
        height: 100dvh; /* Use dynamic viewport height for mobile */
        display: flex;
        flex-direction: column;
        background: #f5f5f5;
        overflow: hidden;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        touch-action: none;
        -webkit-overflow-scrolling: none;
    }

    .energy-bar {
        position: absolute;
        top: 1rem;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0, 0, 0, 0.7);
        color: white;
        padding: 0.5rem 1.5rem;
        border-radius: 20px;
        display: flex;
        align-items: center;
        gap: 1rem;
        z-index: 100;
        backdrop-filter: blur(10px);
        border: 2px solid rgba(255, 255, 255, 0.2);
    }

    .energy-label {
        font-weight: 600;
        font-size: 0.9rem;
    }

    .energy-value {
        font-weight: 700;
        font-size: 1rem;
    }

    .energy-bar-fill {
        height: 8px;
        background: linear-gradient(90deg, #4CAF50, #8BC34A);
        border-radius: 4px;
        transition: width 0.3s ease;
    }

    .canvas-wrapper {
        flex: 1;
        position: relative;
        overflow: hidden;
        width: 100%;
        height: 100%;
        touch-action: none;
        -webkit-overflow-scrolling: none;
    }

    :global(.canvas-wrapper canvas) {
        display: block;
        width: 100% !important;
        height: 100% !important;
        touch-action: none;
    }

    .action-menu {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        z-index: 200;
        pointer-events: none;
    }

    .action-buttons-top,
    .action-buttons-middle,
    .action-buttons-bottom {
        display: flex;
        justify-content: center;
        gap: 0.5rem;
        pointer-events: auto;
    }

    .action-buttons-top {
        margin-bottom: 0.5rem;
    }

    .action-buttons-bottom {
        margin-top: 0.5rem;
    }

    .action-btn {
        padding: 0.75rem 1.5rem;
        border: none;
        border-radius: 12px;
        font-size: 1rem;
        font-weight: 600;
        color: white;
        cursor: pointer;
        transition: all 0.2s ease;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        min-width: 100px;
    }

    .move-btn {
        background: linear-gradient(135deg, #2196F3, #21CBF3);
    }

    .move-btn:active {
        transform: scale(0.95);
    }

    .attack-btn {
        background: linear-gradient(135deg, #f44336, #e91e63);
    }

    .attack-btn:active {
        transform: scale(0.95);
    }

    .ability-btn {
        background: linear-gradient(135deg, #9C27B0, #E91E63);
    }

    .ability-btn:active {
        transform: scale(0.95);
    }

    .retreat-btn {
        background: linear-gradient(135deg, #757575, #424242);
    }

    .retreat-btn:active {
        transform: scale(0.95);
    }

    .drag-ghost {
        position: fixed;
        pointer-events: none;
        z-index: 10000;
        transform: translate(-50%, -50%);
    }

    .ghost-piece-circle {
        width: 60px;
        height: 60px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
        font-weight: bold;
        color: white;
        text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
        border: 3px solid rgba(255, 255, 255, 0.5);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
        opacity: 0.9;
    }

    @media (max-width: 768px) {
        .energy-bar {
            top: 0.5rem;
            padding: 0.4rem 1rem;
            font-size: 0.85rem;
        }

        .ghost-piece-circle {
            width: 50px;
            height: 50px;
            font-size: 1.25rem;
        }

        .action-menu {
            position: fixed;
            bottom: 180px;
            left: 50%;
            transform: translateX(-50%);
            top: auto;
        }

        .action-btn {
            padding: 1rem 1.5rem;
            font-size: 1.1rem;
            min-width: 120px;
        }
    }
</style>
