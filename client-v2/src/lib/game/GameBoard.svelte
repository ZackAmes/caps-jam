<script lang="ts">
    import { T } from '@threlte/core';
    import type { BoardPiece } from './gameState';
    import { onMount } from 'svelte';
    import * as THREE from 'three';

    interface Props {
        boardPieces: BoardPiece[];
        selectedPiece: { id: number; x: number; y: number } | null;
        onTileClick: (x: number, y: number) => void;
        pendingAction: 'move' | 'attack' | 'ability' | 'retreat' | null;
    }

    let { boardPieces, selectedPiece, onTileClick, pendingAction }: Props = $props();

    const GRID_WIDTH = 3;
    const GRID_HEIGHT = 7;
    const TILE_SIZE = 1.2;
    const TILE_SPACING = 0.1;

    // Generate tiles
    const tiles = Array.from({ length: GRID_HEIGHT }, (_, y) =>
        Array.from({ length: GRID_WIDTH }, (_, x) => ({ x, y }))
    ).flat();

    function getTileColor(x: number, y: number): string {
        // Checkerboard pattern
        return (x + y) % 2 === 0 ? '#e8e8e8' : '#d0d0d0';
    }

    function getTilePosition(x: number, y: number): [number, number, number] {
        // Center the board
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

    function isTileSelected(x: number, y: number): boolean {
        return selectedPiece?.x === x && selectedPiece?.y === y;
    }

    function isTileHighlighted(x: number, y: number): boolean {
        if (!selectedPiece || !pendingAction) return false;
        
        const piece = boardPieces.find(p => p.id === selectedPiece.id);
        if (!piece) return false;

        if (pendingAction === 'move') {
            // Highlight adjacent tiles for movement
            const dx = Math.abs(x - piece.x);
            const dy = Math.abs(y - piece.y);
            return (dx === 1 && dy === 0) || (dx === 0 && dy === 1);
        } else if (pendingAction === 'attack') {
            // Highlight attackable tiles
            const dx = Math.abs(x - piece.x);
            const dy = Math.abs(y - piece.y);
            return (dx <= 1 && dy <= 1) && (dx + dy > 0);
        }
        
        return false;
    }

    function getPieceColor(type: number, owner: string): string {
        const colors = ['#ff6b6b', '#4ecdc4', '#ffe66d', '#a8e6cf'];
        const baseColor = colors[type % colors.length];
        return owner === 'player1' ? baseColor : '#888888';
    }

    let raycaster = new THREE.Raycaster();
    let mouse = new THREE.Vector2();
    let camera: THREE.Camera | null = null;
    let scene: THREE.Scene | null = null;

    function handleClick(event: MouseEvent | TouchEvent) {
        if (!camera || !scene) return;

        const canvas = event.target as HTMLCanvasElement;
        const rect = canvas.getBoundingClientRect();
        
        let clientX: number, clientY: number;
        if (event instanceof TouchEvent) {
            if (event.touches.length === 0) return;
            clientX = event.touches[0].clientX;
            clientY = event.touches[0].clientY;
        } else {
            clientX = event.clientX;
            clientY = event.clientY;
        }

        mouse.x = ((clientX - rect.left) / rect.width) * 2 - 1;
        mouse.y = -((clientY - rect.top) / rect.height) * 2 + 1;

        raycaster.setFromCamera(mouse, camera);
        
        // Find clicked tile
        for (const tile of tiles) {
            const [x, y, z] = getTilePosition(tile.x, tile.y);
            const tileMesh = new THREE.Mesh(
                new THREE.PlaneGeometry(TILE_SIZE, TILE_SIZE),
                new THREE.MeshBasicMaterial({ visible: false })
            );
            tileMesh.position.set(x, y + 0.5, z);
            tileMesh.rotation.x = -Math.PI / 2;
            
            const intersects = raycaster.intersectObject(tileMesh);
            if (intersects.length > 0) {
                onTileClick(tile.x, tile.y);
                break;
            }
        }
    }
</script>

<T.Group>
    <!-- Tiles -->
    {#each tiles as tile}
        {@const [posX, posY, posZ] = getTilePosition(tile.x, tile.y)}
        {@const isSelected = isTileSelected(tile.x, tile.y)}
        {@const isHighlighted = isTileHighlighted(tile.x, tile.y)}
        {@const color = isSelected ? '#4CAF50' : isHighlighted ? '#FFC107' : getTileColor(tile.x, tile.y)}
        
        <T.Mesh 
            position={[posX, posY, posZ]} 
            rotation={[-Math.PI / 2, 0, 0]}
            on:click={() => onTileClick(tile.x, tile.y)}
        >
            <T.PlaneGeometry args={[TILE_SIZE, TILE_SIZE]} />
            <T.MeshStandardMaterial 
                color={color} 
                emissive={isSelected || isHighlighted ? color : '#000000'}
                emissiveIntensity={isSelected ? 0.3 : isHighlighted ? 0.2 : 0}
            />
        </T.Mesh>
        
        <!-- Rounded rectangle border -->
        <T.Mesh 
            position={[posX, posY + 0.01, posZ]} 
            rotation={[-Math.PI / 2, 0, 0]}
        >
            <T.RingGeometry args={[TILE_SIZE * 0.48, TILE_SIZE * 0.5, 32]} />
            <T.MeshStandardMaterial 
                color="#000000" 
                side={2}
                transparent
                opacity={0.3}
            />
        </T.Mesh>
    {/each}

    <!-- Pieces -->
    {#each boardPieces as piece}
        {@const [posX, posY, posZ] = getPiecePosition(piece.x, piece.y)}
        {@const isSelected = selectedPiece?.id === piece.id}
        {@const color = getPieceColor(piece.type, piece.owner)}
        
        <T.Group position={[posX, posY, posZ]}>
            <!-- Piece base (cylinder) -->
            <T.Mesh>
                <T.CylinderGeometry args={[0.35, 0.35, 0.3, 32]} />
                <T.MeshStandardMaterial 
                    color={color}
                    emissive={isSelected ? color : '#000000'}
                    emissiveIntensity={isSelected ? 0.4 : 0}
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

<svelte:window 
    on:click={handleClick}
    on:touchstart={handleClick}
/>

