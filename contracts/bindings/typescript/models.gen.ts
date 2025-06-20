import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { CairoCustomEnum, BigNumberish } from 'starknet';

// Type definition for `caps::models::Cap` struct
export interface Cap {
	id: BigNumberish;
	owner: string;
	position: Vec2;
}

// Type definition for `caps::models::CapValue` struct
export interface CapValue {
	owner: string;
	position: Vec2;
}

// Type definition for `caps::models::Game` struct
export interface Game {
	id: BigNumberish;
	player1: string;
	player2: string;
	caps_ids: Array<BigNumberish>;
	turn_count: BigNumberish;
}

// Type definition for `caps::models::GameValue` struct
export interface GameValue {
	player1: string;
	player2: string;
	caps_ids: Array<BigNumberish>;
	turn_count: BigNumberish;
}

// Type definition for `caps::models::Global` struct
export interface Global {
	key: BigNumberish;
	games_counter: BigNumberish;
	cap_counter: BigNumberish;
}

// Type definition for `caps::models::GlobalValue` struct
export interface GlobalValue {
	games_counter: BigNumberish;
	cap_counter: BigNumberish;
}

// Type definition for `caps::models::Square` struct
export interface Square {
	game_id: BigNumberish;
	x: BigNumberish;
	y: BigNumberish;
	ids: Array<BigNumberish>;
}

// Type definition for `caps::models::SquareValue` struct
export interface SquareValue {
	ids: Array<BigNumberish>;
}

// Type definition for `caps::models::Vec2` struct
export interface Vec2 {
	x: BigNumberish;
	y: BigNumberish;
}

// Type definition for `caps::models::Action` struct
export interface Action {
	cap_id: BigNumberish;
	action_type: ActionTypeEnum;
}

// Type definition for `caps::systems::actions::actions::Moved` struct
export interface Moved {
	player: string;
	turn: Array<Action>;
}

// Type definition for `caps::systems::actions::actions::MovedValue` struct
export interface MovedValue {
	turn: Array<Action>;
}

// Type definition for `caps::models::ActionType` enum
export const actionType = [
	'Move',
	'Attack',
] as const;
export type ActionType = { 
	Move: Vec2,
	Attack: Vec2,
};
export type ActionTypeEnum = CairoCustomEnum;

export interface SchemaType extends ISchemaType {
	caps: {
		Cap: Cap,
		CapValue: CapValue,
		Game: Game,
		GameValue: GameValue,
		Global: Global,
		GlobalValue: GlobalValue,
		Square: Square,
		SquareValue: SquareValue,
		Vec2: Vec2,
		Action: Action,
		Moved: Moved,
		MovedValue: MovedValue,
	},
}
export const schema: SchemaType = {
	caps: {
		Cap: {
			id: 0,
			owner: "",
		position: { x: 0, y: 0, },
		},
		CapValue: {
			owner: "",
		position: { x: 0, y: 0, },
		},
		Game: {
			id: 0,
			player1: "",
			player2: "",
			caps_ids: [0],
			turn_count: 0,
		},
		GameValue: {
			player1: "",
			player2: "",
			caps_ids: [0],
			turn_count: 0,
		},
		Global: {
			key: 0,
			games_counter: 0,
			cap_counter: 0,
		},
		GlobalValue: {
			games_counter: 0,
			cap_counter: 0,
		},
		Square: {
			game_id: 0,
			x: 0,
			y: 0,
			ids: [0],
		},
		SquareValue: {
			ids: [0],
		},
		Vec2: {
			x: 0,
			y: 0,
		},
		Action: {
			cap_id: 0,
		action_type: new CairoCustomEnum({ 
				Move: { x: 0, y: 0, },
				Attack: undefined, }),
		},
		Moved: {
			player: "",
			turn: [{ cap_id: 0, action_type: new CairoCustomEnum({ 
				Move: { x: 0, y: 0, },
				Attack: undefined, }), }],
		},
		MovedValue: {
			turn: [{ cap_id: 0, action_type: new CairoCustomEnum({ 
				Move: { x: 0, y: 0, },
				Attack: undefined, }), }],
		},
	},
};
export enum ModelsMapping {
	Cap = 'caps-Cap',
	CapValue = 'caps-CapValue',
	Game = 'caps-Game',
	GameValue = 'caps-GameValue',
	Global = 'caps-Global',
	GlobalValue = 'caps-GlobalValue',
	Square = 'caps-Square',
	SquareValue = 'caps-SquareValue',
	Vec2 = 'caps-Vec2',
	Action = 'caps-Action',
	ActionType = 'caps-ActionType',
	Moved = 'caps-Moved',
	MovedValue = 'caps-MovedValue',
}