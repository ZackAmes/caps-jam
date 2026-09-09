import type { CapTypeDef, TurnRecord, PieceSnapshot, TurnAction } from '@caps/game-core/types';
export const square = (x: number, y: number) => `${String.fromCharCode(65 + x)}${y + 1}`;
export function actionLabel(action: TurnAction, pieces: PieceSnapshot[], defs: Map<number, CapTypeDef>): string {
    const piece = pieces.find(p => p.id === action.capId);
    const name = `${piece ? defs.get(piece.capType)?.name ?? 'Piece' : 'Piece'} #${action.capId}`;
    if (action.kind === 'StackAbility') return `${name}: negate effect #${action.targetId}`;
    return `${name}: ${action.kind === 'Play' ? 'deploy at' : action.kind === 'Move' ? 'move / attack toward' : 'ability targeting'} ${square(action.x, action.y)}`;
}
export function turnOutcomes(record: TurnRecord, defs: Map<number, CapTypeDef>): string[] {
    const result: string[] = [];
    for (const after of record.after) {
        const before = record.before.find(c => c.id === after.id);
        if (!before) continue;
        const name = `P${after.playerSlot + 1} ${defs.get(after.capType)?.name ?? 'piece'} #${after.id}`;
        if (after.dead && !before.dead) result.push(`${name} destroyed`);
        else if (before.x !== null && after.x === null) result.push(`${name} captured; eligible on turn ${after.availableTurn + 1}`);
        else if (after.x !== null && after.y !== null && (before.x !== after.x || before.y !== after.y)) result.push(`${name}: ${before.x === null ? 'hand' : square(before.x, before.y!)} → ${square(after.x, after.y)}`);
        if (before.health !== after.health) result.push(`${name}: HP ${before.health} → ${after.health}`);
        if (before.shield !== after.shield) result.push(`${name}: shield ${before.shield} → ${after.shield}`);
        if (before.stunnedTurns !== after.stunnedTurns) result.push(`${name}: stun ${before.stunnedTurns} → ${after.stunnedTurns}`);
    }
    return result;
}
