import { DojoProvider, DojoCall } from "@dojoengine/core";
import { Account, AccountInterface, BigNumberish, CairoOption, CairoCustomEnum, ByteArray } from "starknet";
import * as models from "./models.gen";

export function setupWorld(provider: DojoProvider) {

	const build_actions_createGame_calldata = (p1: string, p2: string): DojoCall => {
		return {
			contractName: "actions",
			entrypoint: "create_game",
			calldata: [p1, p2],
		};
	};

	const actions_createGame = async (snAccount: Account | AccountInterface, p1: string, p2: string) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_createGame_calldata(p1, p2),
				"dojo_starter",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_getGame_calldata = (gameId: BigNumberish): DojoCall => {
		return {
			contractName: "actions",
			entrypoint: "get_game",
			calldata: [gameId],
		};
	};

	const actions_getGame = async (gameId: BigNumberish) => {
		try {
			return await provider.call("dojo_starter", build_actions_getGame_calldata(gameId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_actions_takeTurn_calldata = (gameId: BigNumberish, turn: models.Vec2): DojoCall => {
		return {
			contractName: "actions",
			entrypoint: "take_turn",
			calldata: [gameId, turn],
		};
	};

	const actions_takeTurn = async (snAccount: Account | AccountInterface, gameId: BigNumberish, turn: models.Vec2) => {
		try {
			return await provider.execute(
				snAccount,
				build_actions_takeTurn_calldata(gameId, turn),
				"dojo_starter",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_planetelo_createMatch_calldata = (p1: string, p2: string, playlistId: BigNumberish): DojoCall => {
		return {
			contractName: "planetelo",
			entrypoint: "create_match",
			calldata: [p1, p2, playlistId],
		};
	};

	const planetelo_createMatch = async (snAccount: Account | AccountInterface, p1: string, p2: string, playlistId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_planetelo_createMatch_calldata(p1, p2, playlistId),
				"dojo_starter",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_planetelo_getResult_calldata = (sessionId: BigNumberish): DojoCall => {
		return {
			contractName: "planetelo",
			entrypoint: "get_result",
			calldata: [sessionId],
		};
	};

	const planetelo_getResult = async (sessionId: BigNumberish) => {
		try {
			return await provider.call("dojo_starter", build_planetelo_getResult_calldata(sessionId));
		} catch (error) {
			console.error(error);
			throw error;
		}
	};

	const build_planetelo_settleMatch_calldata = (matchId: BigNumberish): DojoCall => {
		return {
			contractName: "planetelo",
			entrypoint: "settle_match",
			calldata: [matchId],
		};
	};

	const planetelo_settleMatch = async (snAccount: Account | AccountInterface, matchId: BigNumberish) => {
		try {
			return await provider.execute(
				snAccount,
				build_planetelo_settleMatch_calldata(matchId),
				"dojo_starter",
			);
		} catch (error) {
			console.error(error);
			throw error;
		}
	};



	return {
		actions: {
			createGame: actions_createGame,
			buildCreateGameCalldata: build_actions_createGame_calldata,
			getGame: actions_getGame,
			buildGetGameCalldata: build_actions_getGame_calldata,
			takeTurn: actions_takeTurn,
			buildTakeTurnCalldata: build_actions_takeTurn_calldata,
		},
		planetelo: {
			createMatch: planetelo_createMatch,
			buildCreateMatchCalldata: build_planetelo_createMatch_calldata,
			getResult: planetelo_getResult,
			buildGetResultCalldata: build_planetelo_getResult_calldata,
			settleMatch: planetelo_settleMatch,
			buildSettleMatchCalldata: build_planetelo_settleMatch_calldata,
		},
	};
}