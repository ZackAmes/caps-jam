import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { CairoCustomEnum, BigNumberish } from 'starknet';

// Type definition for `caps::models::Cap` struct
export interface Cap {
	id: BigNumberish;
	owner: string;
	position: Vec2;
	cap_type: BigNumberish;
	dmg_taken: BigNumberish;
}

// Type definition for `caps::models::CapType` struct
export interface CapType {
	id: BigNumberish;
	name: string;
	description: string;
	move_cost: BigNumberish;
	attack_cost: BigNumberish;
	attack_range: Array<Vec2>;
	ability_range: Array<Vec2>;
	ability_description: string;
	move_range: Vec2;
	attack_dmg: BigNumberish;
	base_health: BigNumberish;
	ability_target: TargetTypeEnum;
	ability_cost: BigNumberish;
}

// Type definition for `caps::models::CapTypeValue` struct
export interface CapTypeValue {
	name: string;
	description: string;
	move_cost: BigNumberish;
	attack_cost: BigNumberish;
	attack_range: Array<Vec2>;
	ability_range: Array<Vec2>;
	ability_description: string;
	move_range: Vec2;
	attack_dmg: BigNumberish;
	base_health: BigNumberish;
	ability_target: TargetTypeEnum;
	ability_cost: BigNumberish;
}

// Type definition for `caps::models::CapValue` struct
export interface CapValue {
	owner: string;
	position: Vec2;
	cap_type: BigNumberish;
	dmg_taken: BigNumberish;
}

// Type definition for `caps::models::Effect` struct
export interface Effect {
	game_id: BigNumberish;
	effect_id: BigNumberish;
	effect_type: EffectTypeEnum;
	target: EffectTargetEnum;
}

// Type definition for `caps::models::EffectValue` struct
export interface EffectValue {
	effect_type: EffectTypeEnum;
	target: EffectTargetEnum;
}

// Type definition for `caps::models::Game` struct
export interface Game {
	id: BigNumberish;
	player1: string;
	player2: string;
	caps_ids: Array<BigNumberish>;
	turn_count: BigNumberish;
	over: boolean;
	active_start_of_turn_effects: Array<BigNumberish>;
	active_damage_step_effects: Array<BigNumberish>;
	active_move_step_effects: Array<BigNumberish>;
	active_end_of_turn_effects: Array<BigNumberish>;
}

// Type definition for `caps::models::GameValue` struct
export interface GameValue {
	player1: string;
	player2: string;
	caps_ids: Array<BigNumberish>;
	turn_count: BigNumberish;
	over: boolean;
	active_start_of_turn_effects: Array<BigNumberish>;
	active_damage_step_effects: Array<BigNumberish>;
	active_move_step_effects: Array<BigNumberish>;
	active_end_of_turn_effects: Array<BigNumberish>;
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

// Type definition for `caps::planetelo::AgentGames` struct
export interface AgentGames {
	id: BigNumberish;
	game_ids: Array<BigNumberish>;
	address: string;
}

// Type definition for `caps::planetelo::AgentGamesValue` struct
export interface AgentGamesValue {
	game_ids: Array<BigNumberish>;
	address: string;
}

// Type definition for `caps::planetelo::Player` struct
export interface Player {
	address: string;
	in_game: boolean;
	game_id: BigNumberish;
}

// Type definition for `caps::planetelo::PlayerValue` struct
export interface PlayerValue {
	in_game: boolean;
	game_id: BigNumberish;
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

// Type definition for `caps::models::EffectTarget` enum
export const effectTarget = [
	'Cap',
	'Square',
] as const;
export type EffectTarget = { 
	Cap: BigNumberish,
	Square: Vec2,
};
export type EffectTargetEnum = CairoCustomEnum;

// Type definition for `caps::models::EffectType` enum
export const effectType = [
	'DamageBuff',
	'Shield',
	'Heal',
	'DOT',
	'MoveBonus',
] as const;
export type EffectType = { [key in typeof effectType[number]]: string };
export type EffectTypeEnum = CairoCustomEnum;

// Type definition for `caps::models::TargetType` enum
export const targetType = [
	'None',
	'SelfCap',
	'TeamCap',
	'OpponentCap',
	'AnyCap',
	'AnySquare',
] as const;
export type TargetType = { [key in typeof targetType[number]]: string };
export type TargetTypeEnum = CairoCustomEnum;

// Type definition for `caps::models::ActionType` enum
export const actionType = [
	'Move',
	'Attack',
	'Ability',
] as const;
export type ActionType = { 
	Move: Vec2,
	Attack: Vec2,
	Ability: Vec2,
};
export type ActionTypeEnum = CairoCustomEnum;

export interface SchemaType extends ISchemaType {
	caps: {
		Cap: Cap,
		CapType: CapType,
		CapTypeValue: CapTypeValue,
		CapValue: CapValue,
		Effect: Effect,
		EffectValue: EffectValue,
		Game: Game,
		GameValue: GameValue,
		Global: Global,
		GlobalValue: GlobalValue,
		Square: Square,
		SquareValue: SquareValue,
		Vec2: Vec2,
		AgentGames: AgentGames,
		AgentGamesValue: AgentGamesValue,
		Player: Player,
		PlayerValue: PlayerValue,
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
			cap_type: 0,
			dmg_taken: 0,
		},
		CapType: {
			id: 0,
		name: "",
		description: "",
			move_cost: 0,
			attack_cost: 0,
			attack_range: [{ x: 0, y: 0, }],
			ability_range: [{ x: 0, y: 0, }],
		ability_description: "",
		move_range: { x: 0, y: 0, },
			attack_dmg: 0,
			base_health: 0,
		ability_target: new CairoCustomEnum({ 
					None: "",
				SelfCap: undefined,
				TeamCap: undefined,
				OpponentCap: undefined,
				AnyCap: undefined,
				AnySquare: undefined, }),
			ability_cost: 0,
		},
		CapTypeValue: {
		name: "",
		description: "",
			move_cost: 0,
			attack_cost: 0,
			attack_range: [{ x: 0, y: 0, }],
			ability_range: [{ x: 0, y: 0, }],
		ability_description: "",
		move_range: { x: 0, y: 0, },
			attack_dmg: 0,
			base_health: 0,
		ability_target: new CairoCustomEnum({ 
					None: "",
				SelfCap: undefined,
				TeamCap: undefined,
				OpponentCap: undefined,
				AnyCap: undefined,
				AnySquare: undefined, }),
			ability_cost: 0,
		},
		CapValue: {
			owner: "",
		position: { x: 0, y: 0, },
			cap_type: 0,
			dmg_taken: 0,
		},
		Effect: {
			game_id: 0,
			effect_id: 0,
		effect_type: new CairoCustomEnum({ 
					DamageBuff: "",
				Shield: undefined,
				Heal: undefined,
				DOT: undefined,
				MoveBonus: undefined, }),
		target: new CairoCustomEnum({ 
					Cap: 0,
				Square: undefined, }),
		},
		EffectValue: {
		effect_type: new CairoCustomEnum({ 
					DamageBuff: "",
				Shield: undefined,
				Heal: undefined,
				DOT: undefined,
				MoveBonus: undefined, }),
		target: new CairoCustomEnum({ 
					Cap: 0,
				Square: undefined, }),
		},
		Game: {
			id: 0,
			player1: "",
			player2: "",
			caps_ids: [0],
			turn_count: 0,
			over: false,
			active_start_of_turn_effects: [0],
			active_damage_step_effects: [0],
			active_move_step_effects: [0],
			active_end_of_turn_effects: [0],
		},
		GameValue: {
			player1: "",
			player2: "",
			caps_ids: [0],
			turn_count: 0,
			over: false,
			active_start_of_turn_effects: [0],
			active_damage_step_effects: [0],
			active_move_step_effects: [0],
			active_end_of_turn_effects: [0],
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
		AgentGames: {
			id: 0,
			game_ids: [0],
			address: "",
		},
		AgentGamesValue: {
			game_ids: [0],
			address: "",
		},
		Player: {
			address: "",
			in_game: false,
			game_id: 0,
		},
		PlayerValue: {
			in_game: false,
			game_id: 0,
		},
		Action: {
			cap_id: 0,
		action_type: new CairoCustomEnum({ 
				Move: { x: 0, y: 0, },
				Attack: undefined,
				Ability: undefined, }),
		},
		Moved: {
			player: "",
			turn: [{ cap_id: 0, action_type: new CairoCustomEnum({ 
				Move: { x: 0, y: 0, },
				Attack: undefined,
				Ability: undefined, }), }],
		},
		MovedValue: {
			turn: [{ cap_id: 0, action_type: new CairoCustomEnum({ 
				Move: { x: 0, y: 0, },
				Attack: undefined,
				Ability: undefined, }), }],
		},
	},
};
export enum ModelsMapping {
	Cap = 'caps-Cap',
	CapType = 'caps-CapType',
	CapTypeValue = 'caps-CapTypeValue',
	CapValue = 'caps-CapValue',
	Effect = 'caps-Effect',
	EffectTarget = 'caps-EffectTarget',
	EffectType = 'caps-EffectType',
	EffectValue = 'caps-EffectValue',
	Game = 'caps-Game',
	GameValue = 'caps-GameValue',
	Global = 'caps-Global',
	GlobalValue = 'caps-GlobalValue',
	Square = 'caps-Square',
	SquareValue = 'caps-SquareValue',
	TargetType = 'caps-TargetType',
	Vec2 = 'caps-Vec2',
	AgentGames = 'caps-AgentGames',
	AgentGamesValue = 'caps-AgentGamesValue',
	Player = 'caps-Player',
	PlayerValue = 'caps-PlayerValue',
	Action = 'caps-Action',
	ActionType = 'caps-ActionType',
	Moved = 'caps-Moved',
	MovedValue = 'caps-MovedValue',
}