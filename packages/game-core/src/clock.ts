export interface GameClock {
    gameId: number;
    enabled: boolean;
    p1Seconds: number;
    p2Seconds: number;
    runningSince: number;
    /** 2 means no timeout; otherwise identifies the losing side. */
    timedOutSlot: number;
    chainTime: number;
}

export function decodeClock(raw: string[]): GameClock {
    if (raw.length !== 7) throw new Error('Invalid clock response');
    const values = raw.map(Number);
    if (values.some(v => !Number.isSafeInteger(v) || v < 0) || values[1] > 1 || values[5] > 2) {
        throw new Error('Invalid clock values');
    }
    return {
        gameId: values[0], enabled: values[1] === 1,
        p1Seconds: values[2], p2Seconds: values[3], runningSince: values[4],
        timedOutSlot: values[5], chainTime: values[6],
    };
}

/** The bot uses chainTime directly; the client may extrapolate from its receipt time. */
export function clockRemaining(clock: GameClock, turn: number, over: boolean, chainNow = clock.chainTime): [number, number] | null {
    if (!clock.enabled) return null;
    const result: [number, number] = [clock.p1Seconds, clock.p2Seconds];
    if (!over) {
        const slot = turn % 2;
        result[slot] = Math.max(0, result[slot] - Math.max(0, chainNow - clock.runningSince));
    }
    return result;
}

export function clockLabel(seconds: number | null | undefined): string {
    if (seconds == null) return '—';
    const rounded = Math.max(0, Math.ceil(seconds));
    return `${Math.floor(rounded / 60)}:${String(rounded % 60).padStart(2, '0')}`;
}
