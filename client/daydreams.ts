import {
    context,
    createContainer,
    createDreams,
    createMemoryStore,
    input,
    render,
    LogLevel,
    validateEnv,
    action,
    Agent,
  } from "@daydreamsai/core";
  import { createChromaVectorStore } from "@daydreamsai/chromadb";
  import { z } from "zod";
  import { google } from "@ai-sdk/google";
  import { discord } from "@daydreamsai/discord";
  import { StarknetChain } from "@daydreamsai/defai";
  // Validate environment before proceeding
  const env = validateEnv(
    z.object({
      GOOGLE_GENERATIVE_AI_API_KEY: z.string().min(1, "GOOGLE_GENERATIVE_API_KEY is required"),
      STARKNET_ADDRESS: z.string().min(1, "STARKNET_ADDRESS is required"),
      STARKNET_PRIVATE_KEY: z.string().min(1, "STARKNET_PRIVATE_KEY is required"),
    })
  );

import { Contract, type Abi } from "starknet";
import { RpcProvider } from "starknet";
import { shortString } from "starknet";
import caps_manifest from "../contracts/manifest_sepolia.json";

let rpc = new RpcProvider({
    nodeUrl: "https://api.cartridge.gg/x/starknet/sepolia"
})
let caps_actions_contract = new Contract(
    caps_manifest.contracts[0].abi,
    caps_manifest.contracts[0].address,
    rpc
).typedv2(caps_manifest.contracts[0].abi as Abi)

let caps_planetelo_contract = new Contract(
    caps_manifest.contracts[1].abi,
    caps_manifest.contracts[1].address,
    rpc
).typedv2(caps_manifest.contracts[1].abi as Abi)

const capsContext = context({
        type: "caps",
        schema: z.object({
          id: z.string(),
          piece_info: z.string(),
          game_state: z.string(),
        }),
      
        key({ id }) {
          return id;
        },
      
        create(state) {
          return {
            piece_info: state.args.piece_info,
            game_state: state.args.game_state,
          };
        },
      
        render({ memory }) {
          console.log('memory', memory)
      
          return render(caps_template, {
            piece_info: memory.piece_info,
            game_state: memory.game_state,
          });
        },
      });

      export const caps_check = (chain: StarknetChain) => input({
        schema: z.object({
          text: z.string(),
        }),
        subscribe(send, { container }) {
          // Check mentions every minute
          let index = 0;
          let timeout: ReturnType<typeof setTimeout>;
      
          // Function to schedule the next thought with random timing
          const scheduleNextThought = async () => {
            // Random delay between 3 and 10 minutes (180000-600000 ms)
            const delay = 100000;
      
            console.log(`Scheduling next ponziland check in ${delay / 60000} minutes`);
      

            timeout = setTimeout(async () => {

                let active_games = await caps_planetelo_contract.get_agent_games()

                console.log('active_games', active_games)
        
      
                let piece_info = await caps_actions_contract.get_piece_info()
                let game_state = await caps_actions_contract.get_game_state()
      
              let context = {
                id: "caps",
                piece_info: piece_info,
                game_state: game_state,
              }

              console.log('caps context', context)
      
              send(capsContext, context, { text: "Take your turn" });
              index += 1;
      
              // Schedule the next thought
              scheduleNextThought();
            }, delay);
          };
      
          // Start the first thought cycle
          scheduleNextThought();
      
          return () => clearTimeout(timeout);
        },
      });

      
export const take_turn = (chain: StarknetChain) => action({
    name: "take_turn",
    description: "Take a turn in the game",
    schema: z.object({
        actions: z.array(z.object({
            type: z.string().describe("should be Move or Attack"),
            arg1: z.number().describe("should be the direction for Move, or the x coord of the target for Attack"),
            arg2: z.number().describe("should be the y coord of the target for Attack")
            
    }))}),
    async handler(args: { actions: { type: string, arg1: number, arg2: number }[] }, ctx: any, agent: Agent) {
        console.log('actions', args)
    }
})
      

  const caps_template = `
  
    You are playing an onchain game called caps, where you move pieces on a board similar to chess. Each turn you have a certain amount of
    energy you can use to take actions. Actions include moving pieces and attacking with them, and you turn consists of an array of actions.

    Every piece has a move cost, attack cost, move range, attack range, attack damage,and health.

    You can move the same piece multiple times in a turn, but each move costs energy and is limited by the move range.
    A move can only be horizontal or vertical, and the piece has a different move range for each direction. 
    
    Moves are in the format of { direction, distance }, where direction is one of the following:
     - 0: up
     - 1: down
     - 2: left
     - 3: right

     The distance is the number of squares to move in the direction.

     So if a piece has a move range of {x: 2, y: 2}, then it can move 2 squares in the x direction and 2 squares in the y direction,
     and valid move formats are: 
      - {direction: 0,1,2, or 3, distance: 1 or 2}

      However, if a piece has a move range of {x: 1, y: 2}, then it can only move 1 square in the x direction and 2 squares in the y direction,
      and valid move formats are:
      - {direction: 0,1, distance: 1}
      - {direction: 2,3, distance: 1 or 2}

      You can only move a piece if it has enough energy to move.

      Attacks take a pair of coordinates as an argument, where the coords are the target of the attack.

      The attack range of a piece is all of the cooridates it is able to hit relative to its position.
      For example, if a piece has an attack range that includes {x: 1, y: 1}, and its location is {x:3, y:3}, then it can attack the following coordinates:
      - {x: 2, y: 2}
      - {x: 4, y: 4}
      - {x: 2, y: 4}
      - {x: 4, y: 2}

      Or if the piece has an attack range that includes {x: 1, y: 0}, and its location is {x:3, y:3}, then it can attack the following coordinates:
      - {x: 2, y: 3}
      - {x: 4, y: 3}

      You can only attack a piece if it is in the attack range of the piece, and if you have enough energy to attack.

      Remember that a pieces move cost is different from its attack cost, and that a piece can only move to a coordinate if it has enough energy to move.

      Also, remember that pieces cannot move to a coordinate if it is already occupied by a piece, and can only attack opponents pieces.

      Here are all the pieces that are in the current game: 
      {{piece_info}}

      Here is the current game state:
      {{game_state}}

      Remember that the most important thing is to submit valid moves.

  `
  
  const container = createContainer();

  const chain = new StarknetChain({
    address: env.STARKNET_ADDRESS!,
    privateKey: env.STARKNET_PRIVATE_KEY!,
    rpcUrl: "https://api.cartridge.gg/x/starknet/sepolia",
  });

  const agent = createDreams({
    model: google("gemini-2.0-flash-001"),
    container,
    extensions: [discord],
    memory: {
      store: createMemoryStore(),
      vector: createChromaVectorStore("agent", "http://localhost:8000"),
      vectorModel: google("gemini-2.0-flash-001"),
    },
    inputs: {
      caps_check: caps_check(chain),
    },
    actions: [
        take_turn(chain),
],
  });
  
  console.log("Starting Daydreams Discord Bot...");
  await agent.start();
  console.log("Daydreams Discord Bot started");