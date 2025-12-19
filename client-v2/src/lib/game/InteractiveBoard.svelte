<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import { T } from '@threlte/core';
    import { interactivity } from '@threlte/extras';
    import * as THREE from 'three';
    import type { BoardPiece, GameState } from './gameState';

    interface Props {
        gameState: GameState;
        selectedBoardPiece: BoardPiece | null;
        pendingAction: 'play' | 'move' | 'attack' | 'ability' | 'retreat' | null;
        draggingHandPiece?: { index: number; piece: any; x: number; y: number } | null;
        onTileClick: (x: number, y: number) => void;
        onPieceClick: (piece: BoardPiece) => void;
        onTileDrop?: (x: number, y: number) => void;
        onPieceMove?: (pieceId: number, x: number, y: number) => void;
    }

    let { gameState, selectedBoardPiece, pendingAction, draggingHandPiece, onTileClick, onPieceClick, onTileDrop, onPieceMove }: Props = $props();
    
    // Drag state
    let draggingPiece = $state<{ id: number; worldPos: [number, number, number]; offset: [number, number, number] } | null>(null);

    const GRID_WIDTH = 3;
    const GRID_HEIGHT = 7;
    const TILE_SIZE = 1.2;
    const TILE_SPACING = 0.15;

    // Generate tiles
    const tiles = Array.from({ length: GRID_HEIGHT }, (_, y) =>
        Array.from({ length: GRID_WIDTH }, (_, x) => ({ x, y }))
    ).flat();

    function getTilePosition(x: number, y: number): [number, number, number] {
        const offsetX = -(GRID_WIDTH - 1) * (TILE_SIZE + TILE_SPACING) / 2;
        const offsetZ = -(GRID_HEIGHT - 1) * (TILE_SIZE + TILE_SPACING) / 2;
        
        return [
            offsetX + x * (TILE_SIZE + TILE_SPACING),
            0,
            offsetZ + y * (TILE_SIZE + TILE_SPACING)
        ];
    }

    function getPiecePosition(x: number, y: number): [number, number, number] {
        const [posX, , posZ] = getTilePosition(x, y);
        return [posX, 0.3, posZ];
    }

    function getPieceColor(type: number, owner: string): string {
        const colors = ['#ff6b6b', '#4ecdc4', '#ffe66d', '#a8e6cf'];
        const baseColor = colors[type % colors.length];
        return owner === 'player1' ? baseColor : '#888888';
    }

    function isTileHighlighted(x: number, y: number): boolean {
        if (!selectedBoardPiece || !pendingAction) return false;
        
        const piece = gameState.boardPieces.find(p => p.id === selectedBoardPiece!.id);
        if (!piece) return false;

        if (pendingAction === 'move') {
            const dx = Math.abs(x - piece.x);
            const dy = Math.abs(y - piece.y);
            return (dx === 1 && dy === 0) || (dx === 0 && dy === 1);
        } else if (pendingAction === 'attack') {
            const dx = Math.abs(x - piece.x);
            const dy = Math.abs(y - piece.y);
            return (dx <= 1 && dy <= 1) && (dx + dy > 0);
        }
        
        return false;
    }

    function isTilePlayable(x: number, y: number): boolean {
        // Check if tile is empty (for playing pieces)
        // Also highlight if dragging a hand piece
        if (draggingHandPiece) {
            return !gameState.boardPieces.some(p => p.x === x && p.y === y);
        }
        return false;
    }

    function getNearestTile(worldX: number, worldZ: number): { x: number; y: number } | null {
        let nearestTile: { x: number; y: number; dist: number } | null = null;
        
        for (const tile of tiles) {
            const [tileX, , tileZ] = getTilePosition(tile.x, tile.y);
            const dist = Math.sqrt((worldX - tileX) ** 2 + (worldZ - tileZ) ** 2);
            
            if (!nearestTile || dist < nearestTile.dist) {
                nearestTile = { x: tile.x, y: tile.y, dist };
            }
        }
        
        return nearestTile ? { x: nearestTile.x, y: nearestTile.y } : null;
    }

    function handlePointerDown(piece: BoardPiece, event: any) {
        if (piece.owner !== 'player1' || !piece.canMove) return;
        
        const [currentX, , currentZ] = getPiecePosition(piece.x, piece.y);
        const worldPos = event.point;
        
        draggingPiece = {
            id: piece.id,
            worldPos: [worldPos.x, 0.3, worldPos.z],
            offset: [worldPos.x - currentX, 0, worldPos.z - currentZ]
        };
        
        event.stopPropagation();
    }

    function handlePointerMove(event: any) {
        if (!draggingPiece) return;
        
        const worldPos = event.point || event;
        if (worldPos && worldPos.x !== undefined) {
            const [offsetX, , offsetZ] = draggingPiece.offset;
            draggingPiece.worldPos = [worldPos.x - offsetX, 0.3, worldPos.z - offsetZ];
        }
    }

    onMount(() => {
        const handleGlobalPointerUp = () => {
            if (draggingPiece) {
                finishDrag();
            }
        };

        window.addEventListener('pointerup', handleGlobalPointerUp);

        return () => {
            window.removeEventListener('pointerup', handleGlobalPointerUp);
        };
    });

    function finishDrag() {
        if (!draggingPiece) return;
        
        const piece = gameState.boardPieces.find(p => p.id === draggingPiece!.id);
        if (piece) {
            const [finalX, , finalZ] = draggingPiece!.worldPos;
            const nearestTile = getNearestTile(finalX, finalZ);
            
            if (nearestTile) {
                const dx = Math.abs(nearestTile.x - piece.x);
                const dy = Math.abs(nearestTile.y - piece.y);
                const tileEmpty = !gameState.boardPieces.some(p => 
                    p.id !== piece.id && p.x === nearestTile.x && p.y === nearestTile.y
                );
                
                if (tileEmpty && ((dx === 1 && dy === 0) || (dx === 0 && dy === 1))) {
                    if (onPieceMove) {
                        onPieceMove(piece.id, nearestTile.x, nearestTile.y);
                    }
                }
            }
        }
        
        draggingPiece = null;
    }

    function handlePointerUp(piece: BoardPiece, event: any) {
        if (draggingPiece?.id === piece.id) {
            finishDrag();
            event.stopPropagation();
        }
    }

    // Helper to create rounded rectangle shape
    function createRoundedRectShape(width: number, height: number, radius: number): THREE.Shape {
        const shape = new THREE.Shape();
        const w = width / 2;
        const h = height / 2;
        
        shape.moveTo(-w + radius, -h);
        shape.lineTo(w - radius, -h);
        shape.quadraticCurveTo(w, -h, w, -h + radius);
        shape.lineTo(w, h - radius);
        shape.quadraticCurveTo(w, h, w - radius, h);
        shape.lineTo(-w + radius, h);
        shape.quadraticCurveTo(-w, h, -w, h - radius);
        shape.lineTo(-w, -h + radius);
        shape.quadraticCurveTo(-w, -h, -w + radius, -h);
        
        return shape;
    }

    // Call interactivity in the main body of this child component
    interactivity();
</script>

<T.Group>
    <!-- Tiles -->
    {#each tiles as tile}
        {@const [posX, posY, posZ] = getTilePosition(tile.x, tile.y)}
        {@const isHighlighted = isTileHighlighted(tile.x, tile.y)}
        {@const isPlayable = isTilePlayable(tile.x, tile.y)}
        {@const piece = gameState.boardPieces.find(p => p.x === tile.x && p.y === tile.y && p.owner === 'player1')}
        {@const isSelected = selectedBoardPiece?.x === tile.x && selectedBoardPiece?.y === tile.y}
        
        {@const color = isSelected ? '#4CAF50' : isHighlighted ? '#FFC107' : isPlayable ? '#81C784' : '#ffffff'}
        
        <T.Mesh 
            position={[posX, posY, posZ]} 
            rotation={[-Math.PI / 2, 0, 0]}
            onclick={() => {
                if (draggingHandPiece && onTileDrop) {
                    onTileDrop(tile.x, tile.y);
                } else {
                    onTileClick(tile.x, tile.y);
                }
            }}
            onpointerup={() => {
                if (draggingHandPiece && onTileDrop) {
                    onTileDrop(tile.x, tile.y);
                }
            }}
        >
            <T.ShapeGeometry args={[createRoundedRectShape(TILE_SIZE * 0.9, TILE_SIZE * 0.9, 0.15)]} />
            <T.MeshStandardMaterial 
                color={color} 
                emissive={isSelected || isHighlighted || isPlayable ? color : '#000000'}
                emissiveIntensity={isSelected ? 0.3 : isHighlighted || isPlayable ? 0.2 : 0}
            />
        </T.Mesh>
        
        <!-- Black border (rounded rectangle outline) -->
        <T.Mesh 
            position={[posX, posY + 0.01, posZ]} 
            rotation={[-Math.PI / 2, 0, 0]}
        >
            <T.ShapeGeometry args={[createRoundedRectShape(TILE_SIZE * 0.95, TILE_SIZE * 0.95, 0.15)]} />
            <T.MeshStandardMaterial 
                color="#000000" 
                side={2}
                transparent
                opacity={0.8}
            />
        </T.Mesh>
    {/each}

    <!-- Pieces -->
    {#each gameState.boardPieces as piece}
        {@const [basePosX, basePosY, basePosZ] = getPiecePosition(piece.x, piece.y)}
        {@const isDragging = draggingPiece?.id === piece.id}
        {@const dragPos = isDragging ? draggingPiece!.worldPos : null}
        {@const [posX, posY, posZ] = dragPos ? dragPos : [basePosX, basePosY, basePosZ]}
        {@const isSelected = selectedBoardPiece?.id === piece.id}
        {@const color = getPieceColor(piece.type, piece.owner)}
        {@const canDrag = piece.owner === 'player1' && piece.canMove}
        
        <T.Group position={[posX, posY, posZ]}>
            <!-- Piece base (cylinder) -->
            <T.Mesh
                onclick={() => {
                    if (piece.owner === 'player1' && !isDragging) {
                        onPieceClick(piece);
                    }
                }}
                onpointerdown={(e: any) => handlePointerDown(piece, e)}
                onpointermove={(e: any) => {
                    if (draggingPiece?.id === piece.id) {
                        handlePointerMove(e);
                    }
                }}
                onpointerup={(e: any) => handlePointerUp(piece, e)}
            >
                <T.CylinderGeometry args={[0.35, 0.35, 0.3, 32]} />
                <T.MeshStandardMaterial 
                    color={color}
                    emissive={isSelected || isDragging ? color : '#000000'}
                    emissiveIntensity={isSelected || isDragging ? 0.4 : 0}
                />
            </T.Mesh>
            
            <!-- Health bar -->
            <T.Mesh position={[0, 0.25, 0]}>
                <T.BoxGeometry args={[0.6, 0.05, 0.05]} />
                <T.MeshStandardMaterial color="#333" />
            </T.Mesh>
            <T.Mesh position={[-0.3 + (piece.health / piece.maxHealth) * 0.3, 0.25, 0]}>
                <T.BoxGeometry args={[(piece.health / piece.maxHealth) * 0.6, 0.05, 0.05]} />
                <T.MeshStandardMaterial color={piece.health / piece.maxHealth > 0.5 ? '#4CAF50' : '#f44336'} />
            </T.Mesh>
        </T.Group>
    {/each}
</T.Group>

