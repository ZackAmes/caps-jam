/** Read the board and its related state at the same turn boundary. */
export async function consistentSnapshot<G extends {turnCount:number; over:boolean}, D>(
    readGame: () => Promise<G | null>, readDetails: (game:G) => Promise<D>, minimumTurn = 0,
): Promise<{game:G; details:D}> {
    for (let attempt = 0; attempt < 3; attempt++) {
        const game = await readGame();
        if (!game) throw new Error('Game not found');
        if (game.turnCount < minimumTurn) throw new Error('Transaction confirmed; waiting for the RPC state to catch up.');
        const details = await readDetails(game), latest = await readGame();
        if (latest?.turnCount === game.turnCount && latest.over === game.over) return {game,details};
    }
    throw new Error('The game changed while loading; refreshing again.');
}
export function submissionHasLanded(pending: {turn:number; confirmed:boolean} | null, turn:number): boolean {
    return !!pending?.confirmed && turn > pending.turn;
}
