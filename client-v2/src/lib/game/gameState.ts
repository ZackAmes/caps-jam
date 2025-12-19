export interface BoardPiece {
    id: number;
    x: number;
    y: number;
    owner: string;
    type: number;
    health: number;
    maxHealth: number;
    attack: number;
    canMove: boolean;
    canAttack: boolean;
    canUseAbility: boolean;
}

export interface HandPiece {
    id: number;
    type: number;
    health: number;
    maxHealth: number;
    attack: number;
    cost: number;
}

export interface GameState {
    boardPieces: BoardPiece[];
    hand: HandPiece[];
    energy: number;
    maxEnergy: number;
}

export function createMockGameState(): GameState {
    return {
        boardPieces: [
            // Some initial pieces on the board
            {
                id: 1,
                x: 1,
                y: 2,
                owner: 'player1',
                type: 0,
                health: 8,
                maxHealth: 10,
                attack: 3,
                canMove: true,
                canAttack: true,
                canUseAbility: true
            },
            {
                id: 2,
                x: 1,
                y: 4,
                owner: 'player2',
                type: 1,
                health: 10,
                maxHealth: 10,
                attack: 4,
                canMove: true,
                canAttack: true,
                canUseAbility: true
            }
        ],
        hand: [
            { id: 10, type: 0, health: 10, maxHealth: 10, attack: 3, cost: 2 },
            { id: 11, type: 1, health: 8, maxHealth: 8, attack: 4, cost: 3 },
            { id: 12, type: 2, health: 12, maxHealth: 12, attack: 2, cost: 2 },
            { id: 13, type: 3, health: 6, maxHealth: 6, attack: 5, cost: 4 }
        ],
        energy: 5,
        maxEnergy: 5
    };
}

