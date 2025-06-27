import type { SchemaType as ISchemaType } from "@dojoengine/sdk";

import { CairoCustomEnum, type BigNumberish } from 'starknet';

// Type definition for `caps::models::cap::Cap` struct
export interface Cap {
	id: BigNumberish;
	owner: string;
	position: Vec2;
	set_id: BigNumberish;
	cap_type: BigNumberish;
	dmg_taken: BigNumberish;
	shield_amt: BigNumberish;
}

// Type definition for `caps::models::cap::CapType` struct
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

// Type definition for `caps::models::cap::CapTypeValue` struct
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

// Type definition for `caps::models::cap::CapValue` struct
export interface CapValue {
	owner: string;
	position: Vec2;
	set_id: BigNumberish;
	cap_type: BigNumberish;
	dmg_taken: BigNumberish;
	shield_amt: BigNumberish;
}

// Type definition for `caps::models::effect::Effect` struct
export interface Effect {
	game_id: BigNumberish;
	effect_id: BigNumberish;
	effect_type: EffectTypeEnum;
	target: EffectTargetEnum;
	remaining_triggers: BigNumberish;
}

// Type definition for `caps::models::effect::EffectValue` struct
export interface EffectValue {
	effect_type: EffectTypeEnum;
	target: EffectTargetEnum;
	remaining_triggers: BigNumberish;
}

// Type definition for `caps::models::game::Game` struct
export interface Game {
	id: BigNumberish;
	player1: string;
	player2: string;
	caps_ids: Array<BigNumberish>;
	turn_count: BigNumberish;
	over: boolean;
	effect_ids: Array<BigNumberish>;
	last_action_timestamp: BigNumberish;
}

// Type definition for `caps::models::game::GameValue` struct
export interface GameValue {
	player1: string;
	player2: string;
	caps_ids: Array<BigNumberish>;
	turn_count: BigNumberish;
	over: boolean;
	effect_ids: Array<BigNumberish>;
	last_action_timestamp: BigNumberish;
}

// Type definition for `caps::models::game::Global` struct
export interface Global {
	key: BigNumberish;
	games_counter: BigNumberish;
	cap_counter: BigNumberish;
}

// Type definition for `caps::models::game::GlobalValue` struct
export interface GlobalValue {
	games_counter: BigNumberish;
	cap_counter: BigNumberish;
}

// Type definition for `caps::models::game::Vec2` struct
export interface Vec2 {
	x: BigNumberish;
	y: BigNumberish;
}

// Type definition for `caps::models::set::Set` struct
export interface Set {
	id: BigNumberish;
	address: string;
}

// Type definition for `caps::models::set::SetValue` struct
export interface SetValue {
	address: string;
}

// Type definition for `caps::planetelo::AgentGames` struct
export interface AgentGames {
	id: BigNumberish;
	game_ids: Array<BigNumberish>;
	address: string;
	wins: BigNumberish;
	losses: BigNumberish;
}

// Type definition for `caps::planetelo::AgentGamesValue` struct
export interface AgentGamesValue {
	game_ids: Array<BigNumberish>;
	address: string;
	wins: BigNumberish;
	losses: BigNumberish;
}

// Type definition for `caps::planetelo::CustomGames` struct
export interface CustomGames {
	id: BigNumberish;
	player1: string;
	player2: string;
	game_id: BigNumberish;
}

// Type definition for `caps::planetelo::CustomGamesValue` struct
export interface CustomGamesValue {
	player1: string;
	player2: string;
	game_id: BigNumberish;
}

// Type definition for `caps::planetelo::GlobalStats` struct
export interface GlobalStats {
	id: BigNumberish;
	games_played: BigNumberish;
	custom_game_counter: BigNumberish;
}

// Type definition for `caps::planetelo::GlobalStatsValue` struct
export interface GlobalStatsValue {
	games_played: BigNumberish;
	custom_game_counter: BigNumberish;
}

// Type definition for `caps::planetelo::Player` struct
export interface Player {
	address: string;
	in_game: boolean;
	game_id: BigNumberish;
	agent_wins: BigNumberish;
	agent_losses: BigNumberish;
	team: BigNumberish;
	custom_game_ids: Array<BigNumberish>;
}

// Type definition for `caps::planetelo::PlayerValue` struct
export interface PlayerValue {
	in_game: boolean;
	game_id: BigNumberish;
	agent_wins: BigNumberish;
	agent_losses: BigNumberish;
	team: BigNumberish;
	custom_game_ids: Array<BigNumberish>;
}

// Type definition for `caps::models::game::Action` struct
export interface Action {
	cap_id: BigNumberish;
	action_type: ActionTypeEnum;
}

// Type definition for `caps::systems::actions::actions::Moved` struct
export interface Moved {
	player: string;
	game_id: BigNumberish;
	turn_number: BigNumberish;
	turn: Array<Action>;
}

// Type definition for `caps::systems::actions::actions::MovedValue` struct
export interface MovedValue {
	turn: Array<Action>;
}

// Type definition for `caps::models::cap::TargetType` enum
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

// Type definition for `caps::models::effect::EffectTarget` enum
export const effectTarget = [
	'Cap',
	'Square',
] as const;
export type EffectTarget = { 
	Cap: BigNumberish,
	Square: Vec2,
};
export type EffectTargetEnum = CairoCustomEnum;

// Type definition for `caps::models::effect::EffectType` enum
export const effectType = [
	'DamageBuff',
	'Shield',
	'Heal',
	'DOT',
	'MoveBonus',
	'AttackBonus',
	'BonusRange',
	'MoveDiscount',
	'AttackDiscount',
	'AbilityDiscount',
	'ExtraEnergy',
	'Stun',
	'Double',
] as const;
export type EffectType = { [key in typeof effectType[number]]: string };
export type EffectTypeEnum = CairoCustomEnum;

// Type definition for `caps::models::game::ActionType` enum
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
		Vec2: Vec2,
		Set: Set,
		SetValue: SetValue,
		AgentGames: AgentGames,
		AgentGamesValue: AgentGamesValue,
		CustomGames: CustomGames,
		CustomGamesValue: CustomGamesValue,
		GlobalStats: GlobalStats,
		GlobalStatsValue: GlobalStatsValue,
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
			set_id: 0,
			cap_type: 0,
			dmg_taken: 0,
			shield_amt: 0,
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
			set_id: 0,
			cap_type: 0,
			dmg_taken: 0,
			shield_amt: 0,
		},
		Effect: {
			game_id: 0,
			effect_id: 0,
		effect_type: new CairoCustomEnum({ 
					DamageBuff: 0,
				Shield: undefined,
				Heal: undefined,
				DOT: undefined,
				MoveBonus: undefined,
				AttackBonus: undefined,
				BonusRange: undefined,
				MoveDiscount: undefined,
				AttackDiscount: undefined,
				AbilityDiscount: undefined,
				ExtraEnergy: undefined,
				Stun: undefined,
				Double: undefined, }),
		target: new CairoCustomEnum({ 
					Cap: 0,
				Square: undefined, }),
			remaining_triggers: 0,
		},
		EffectValue: {
		effect_type: new CairoCustomEnum({ 
					DamageBuff: 0,
				Shield: undefined,
				Heal: undefined,
				DOT: undefined,
				MoveBonus: undefined,
				AttackBonus: undefined,
				BonusRange: undefined,
				MoveDiscount: undefined,
				AttackDiscount: undefined,
				AbilityDiscount: undefined,
				ExtraEnergy: undefined,
				Stun: undefined,
				Double: undefined, }),
		target: new CairoCustomEnum({ 
					Cap: 0,
				Square: undefined, }),
			remaining_triggers: 0,
		},
		Game: {
			id: 0,
			player1: "",
			player2: "",
			caps_ids: [0],
			turn_count: 0,
			over: false,
			effect_ids: [0],
			last_action_timestamp: 0,
		},
		GameValue: {
			player1: "",
			player2: "",
			caps_ids: [0],
			turn_count: 0,
			over: false,
			effect_ids: [0],
			last_action_timestamp: 0,
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
		Vec2: {
			x: 0,
			y: 0,
		},
		Set: {
			id: 0,
			address: "",
		},
		SetValue: {
			address: "",
		},
		AgentGames: {
			id: 0,
			game_ids: [0],
			address: "",
			wins: 0,
			losses: 0,
		},
		AgentGamesValue: {
			game_ids: [0],
			address: "",
			wins: 0,
			losses: 0,
		},
		CustomGames: {
			id: 0,
			player1: "",
			player2: "",
			game_id: 0,
		},
		CustomGamesValue: {
			player1: "",
			player2: "",
			game_id: 0,
		},
		GlobalStats: {
			id: 0,
			games_played: 0,
			custom_game_counter: 0,
		},
		GlobalStatsValue: {
			games_played: 0,
			custom_game_counter: 0,
		},
		Player: {
			address: "",
			in_game: false,
			game_id: 0,
			agent_wins: 0,
			agent_losses: 0,
			team: 0,
			custom_game_ids: [0],
		},
		PlayerValue: {
			in_game: false,
			game_id: 0,
			agent_wins: 0,
			agent_losses: 0,
			team: 0,
			custom_game_ids: [0],
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
			game_id: 0,
			turn_number: 0,
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
	TargetType = 'caps-TargetType',
	Effect = 'caps-Effect',
	EffectTarget = 'caps-EffectTarget',
	EffectType = 'caps-EffectType',
	EffectValue = 'caps-EffectValue',
	Game = 'caps-Game',
	GameValue = 'caps-GameValue',
	Global = 'caps-Global',
	GlobalValue = 'caps-GlobalValue',
	Vec2 = 'caps-Vec2',
	Set = 'caps-Set',
	SetValue = 'caps-SetValue',
	AgentGames = 'caps-AgentGames',
	AgentGamesValue = 'caps-AgentGamesValue',
	CustomGames = 'caps-CustomGames',
	CustomGamesValue = 'caps-CustomGamesValue',
	GlobalStats = 'caps-GlobalStats',
	GlobalStatsValue = 'caps-GlobalStatsValue',
	Player = 'caps-Player',
	PlayerValue = 'caps-PlayerValue',
	Action = 'caps-Action',
	ActionType = 'caps-ActionType',
	Moved = 'caps-Moved',
	MovedValue = 'caps-MovedValue',
}