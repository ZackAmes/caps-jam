import { pathDistance, type LayoutConfig } from '@caps/game-core/board';
import type { AbilityStack, ChainGame, StackEntry, ChainCap } from '@caps/game-core/types';

export function viewerSlot(game: ChainGame, account: string | null): number | null {
    if (!account) return null;
    if (BigInt(account) === BigInt(game.player1)) {
        return BigInt(game.player1) === BigInt(game.player2) ? game.turnCount % 2 : 0;
    }
    return BigInt(account) === BigInt(game.player2) ? 1 : null;
}

/** Draw exactly the same edges used by movement and range. */
export function pathEdges(layout: LayoutConfig) {
    const edges: { x1: number; y1: number; x2: number; y2: number }[] = [];
    for (let y = 0; y < layout.height; y++) for (let x = 0; x < layout.width; x++) {
        for (const [nx, ny] of layout.neighbors([x, y])) {
            if (y * layout.width + x < ny * layout.width + nx) edges.push({ x1: x, y1: y, x2: nx, y2: ny });
        }
    }
    return edges;
}

export function effectTiming(entry: StackEntry, stack: AbilityStack, turn: number, slot: number | null): string {
    const index = stack.entries.findIndex(e => e.id === entry.id);
    const blocked = stack.entries.slice(index + 1).some(e => e.readyTurn > turn + 1);
    if (entry.readyTurn <= turn + 1) return blocked ? 'Ready · waiting for newer effects above it' : 'Resolves when this turn ends';
    const endingTurn = entry.readyTurn - 1;
    const whose = slot === null ? `P${endingTurn % 2 + 1}’s` : endingTurn % 2 === slot ? 'your' : 'your opponent’s';
    const label = `Ready after ${whose} ${endingTurn === turn + 1 ? 'next turn' : `turn ${endingTurn + 1}`}`;
    return blocked ? `${label} · newer effects resolve first` : label;
}

/** Target geometry independent of current occupancy, useful for previewing an effect. */
export function impactFootprint(entry: StackEntry | undefined, caps: ChainCap[], layout: LayoutConfig): Set<string> {
    const cells = new Set<string>();
    if (!entry) return cells;
    const s = entry.impact.selection;
    for (let y = 0; y < layout.height; y++) for (let x = 0; x < layout.width; x++) {
        if (!layout.isWalkable(x,y)) continue;
        const selected = s.kind === 'Row' ? s.index === y : s.kind === 'Column' ? s.index === x : s.kind === 'Within' ? pathDistance(layout,[s.x,s.y],[x,y]) <= s.radius : caps.some(c=>c.id === s.id && c.x === x && c.y === y && !c.dead);
        if (selected) cells.add(`${x},${y}`);
    }
    return cells;
}

/** Earliest boundary allowed by this entry and every newer entry above it. */
export function resolutionBoundary(entry: StackEntry, stack: AbilityStack, turn: number): number {
    const index = stack.entries.findIndex(e => e.id === entry.id);
    return Math.max(turn + 1, entry.readyTurn, ...stack.entries.slice(Math.max(0,index)).map(e=>e.readyTurn));
}

export const pieceSymbol = (type: number) => ['⚡','◆','⬟','✚','✹','➤','⊘'][type] ?? '●';

/** Rotate only presentation; transactions and history keep canonical map coordinates. */
export function boardPosition(layout: LayoutConfig, x: number, y: number, slot: number | null): [number, number] {
    return slot === 0 ? [layout.width - 1 - x, layout.height - 1 - y] : [x, y];
}
