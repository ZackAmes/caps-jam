import type { LayoutConfig } from '@caps/game-core/board';
import type { AbilityStack, ChainGame, StackEntry } from '@caps/game-core/types';

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
