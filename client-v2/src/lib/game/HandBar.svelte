<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import type { HandPiece } from './gameState';

    interface Props {
        hand: HandPiece[];
        selectedIndex: number | null;
        energy: number;
        onPieceClick: (index: number) => void;
        onPieceDragStart: (index: number, piece: HandPiece, event: PointerEvent) => void;
    }

    let { hand, selectedIndex, energy, onPieceClick, onPieceDragStart }: Props = $props();

    const pieceColors = ['#ff6b6b', '#4ecdc4', '#ffe66d', '#a8e6cf'];
    const pieceNames = ['Warrior', 'Mage', 'Tank', 'Assassin'];

    function getPieceColor(type: number): string {
        return pieceColors[type % pieceColors.length];
    }

    function getPieceName(type: number): string {
        return pieceNames[type % pieceNames.length];
    }

    let draggingIndex = $state<number | null>(null);

    function handlePointerDown(index: number, piece: HandPiece, event: PointerEvent) {
        if (energy < piece.cost) return; // Can't afford
        
        draggingIndex = index;
        onPieceDragStart(index, piece, event);
    }

    onMount(() => {
        const handlePointerMove = () => {
            // Drag tracking is handled in parent
        };

        const handlePointerUp = () => {
            draggingIndex = null;
        };

        window.addEventListener('pointermove', handlePointerMove);
        window.addEventListener('pointerup', handlePointerUp);

        return () => {
            window.removeEventListener('pointermove', handlePointerMove);
            window.removeEventListener('pointerup', handlePointerUp);
        };
    });
</script>

<div class="hand-bar">
    {#each hand.slice(0, 4) as piece, index}
        {@const isSelected = selectedIndex === index}
        {@const isDragging = draggingIndex === index}
        {@const canAfford = energy >= piece.cost}
        <button 
            class="hand-piece"
            class:selected={isSelected}
            class:dragging={isDragging}
            class:unaffordable={!canAfford}
            style="--piece-color: {getPieceColor(piece.type)}"
            onclick={() => onPieceClick(index)}
            onpointerdown={(e) => handlePointerDown(index, piece, e)}
        >
            <div class="piece-icon">
                <div class="piece-circle" style="background: var(--piece-color)">
                    {piece.type + 1}
                </div>
            </div>
            <div class="piece-info">
                <div class="piece-name">{getPieceName(piece.type)}</div>
                <div class="piece-stats">
                    <span class="stat">❤️ {piece.health}</span>
                    <span class="stat">⚔️ {piece.attack}</span>
                    <span class="stat">⚡ {piece.cost}</span>
                </div>
            </div>
        </button>
    {/each}
</div>

<style>
    .hand-bar {
        display: flex;
        gap: 0.75rem;
        padding: 1rem;
        background: linear-gradient(to top, rgba(0, 0, 0, 0.9), rgba(0, 0, 0, 0.7));
        backdrop-filter: blur(10px);
        border-top: 2px solid rgba(255, 255, 255, 0.1);
        overflow-x: auto;
        -webkit-overflow-scrolling: touch;
        scrollbar-width: none;
    }

    .hand-bar::-webkit-scrollbar {
        display: none;
    }

    .hand-piece {
        flex: 0 0 auto;
        width: 120px;
        min-width: 120px;
        height: 140px;
        border: 3px solid rgba(255, 255, 255, 0.3);
        border-radius: 16px;
        background: #2a2a2a;
        color: white;
        cursor: pointer;
        transition: all 0.2s ease;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 0.75rem;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        position: relative;
        overflow: hidden;
    }

    .hand-piece::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: var(--piece-color);
        opacity: 0.3;
        z-index: 0;
    }

    .hand-piece.dragging {
        opacity: 0.5;
        transform: scale(0.9);
        z-index: 1000;
    }

    .hand-piece.unaffordable {
        opacity: 0.5;
        filter: grayscale(0.5);
    }

    .hand-piece.selected {
        border-color: #4CAF50;
        transform: translateY(-8px) scale(1.05);
        box-shadow: 0 8px 24px rgba(76, 175, 80, 0.4);
        z-index: 10;
    }

    .hand-piece:active {
        transform: scale(0.95);
    }

    .piece-icon {
        position: relative;
        z-index: 1;
        margin-bottom: 0.5rem;
    }

    .piece-circle {
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
    }

    .piece-info {
        position: relative;
        z-index: 1;
        text-align: center;
        width: 100%;
    }

    .piece-name {
        font-size: 0.85rem;
        font-weight: 600;
        margin-bottom: 0.4rem;
        text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
    }

    .piece-stats {
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
        font-size: 0.75rem;
    }

    .stat {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.25rem;
    }

    @media (max-width: 768px) {
        .hand-bar {
            padding: 0.75rem;
            gap: 0.5rem;
        }

        .hand-piece {
            width: 100px;
            min-width: 100px;
            height: 120px;
        }

        .piece-circle {
            width: 50px;
            height: 50px;
            font-size: 1.25rem;
        }

        .piece-name {
            font-size: 0.75rem;
        }

        .piece-stats {
            font-size: 0.7rem;
        }
    }
</style>

