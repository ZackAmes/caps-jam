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
  import { CapType } from "../contracts/bindings/typescript/models.gen";
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
      
            console.log(`Scheduling next game check in ${delay / 60000} minutes`);


            let active_games = await caps_planetelo_contract.get_agent_games()

            console.log('active_games', active_games)

      

            timeout = setTimeout(async () => {

                let active_games = await caps_planetelo_contract.get_agent_games()

                console.log('active_games', active_games)

            let to_play = active_games[0];

            let piece_info = await get_piece_info_str(to_play)
            let game_state = await get_game_state_str(to_play)
      
      
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

      const get_piece_info_str = async (game_id: number) => {
        let res = (await caps_actions_contract.get_game(game_id)).unwrap()
        let game_state = { game: res[0], caps: res[1] } 
        let initial_state = { game: res[0], caps: res[1] }
        let cap_types: Array<CapType> = []
        for (let cap of game_state.caps) {
                if (!cap_types.find(cap_type => cap_type.id == cap.cap_type)) {
                    let cap_type = (await caps_actions_contract.get_cap_data(cap.cap_type)).unwrap()
                    cap_types.push(cap_type)
                }
            }
        return cap_types.map(cap_type => {
            return `
            ${cap_type.id}: ${cap_type.name}
            Move Cost: ${cap_type.move_cost}
            Attack Cost: ${cap_type.attack_cost}
            Move Range: ${cap_type.move_range.x}, ${cap_type.move_range.y}
            Attack Range: ${cap_type.attack_range.map(range => `${range.x}, ${range.y}`).join(", ")}
            Attack Damage: ${cap_type.attack_dmg}
            Base Health: ${cap_type.base_health}
            `
        }).join("\n\n")
      }

      const get_game_state_str = async (game_id: number) => {
        let res = (await caps_actions_contract.get_game(game_id)).unwrap()
        let game_state = { game: res[0], caps: res[1] } 
        
        // Create ASCII grid representation
        const gridSize = 7; // Assuming 8x8 board, adjust as needed
        const grid: string[][] = Array(gridSize).fill(null).map(() => Array(gridSize).fill('.'));
        
        // Place caps on the grid
        for (let cap of game_state.caps) {
            const x = cap.position?.x || 0;
            const y = cap.position?.y || 0;
            
            // Ensure position is within bounds
            if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
                grid[y][x] = cap.id.toString();
            }
        }
        
        // Convert grid to ASCII string
        let asciiGrid = '\nGame Board:\n';
        asciiGrid += '  ' + Array.from({length: gridSize}, (_, i) => i).join(' ') + '\n';
        
        for (let y = 0; y < gridSize; y++) {
            asciiGrid += y + ' ' + grid[y].join(' ') + '\n';
        }

        let cap_types: Array<CapType> = []
        for (let cap of game_state.caps) {
                if (!cap_types.find(cap_type => cap_type.id == cap.cap_type)) {
                    let cap_type = (await caps_actions_contract.get_cap_data(cap.cap_type)).unwrap()
                    cap_types.push(cap_type)
                }
            }
        
        
        // Add caps details
        let capsDetails = '\nCaps Details:\n';
        capsDetails += game_state.caps.map(cap => {
          let cap_type = cap_types.find(cap_type => cap_type.id == cap.cap_type);
          let cur_health = cap_type?.base_health - cap.dmg_taken;

            return `Cap ID: ${cap.id}, Position: (${cap.position?.x || 0}, ${cap.position?.y || 0}), Health: ${cur_health}/${cap_type?.base_health || 'N/A'}, Type: ${cap_type?.id}: ${cap_type?.name || 'N/A'}, Owner: ${cap.owner || 'N/A'}`;
        }).join('\n');
        
        return asciiGrid + capsDetails;
      }

      
export const take_turn = (chain: StarknetChain) => action({
    name: "take_turn",
    description: "Take a turn in the game",
    schema: z.object({
        actions: z.array(z.object({
            type: z.string().describe("should be Move or Attack"),
            arg1: z.number().describe("should be the direction for Move, or the x coord of the target for Attack"),
            arg2: z.number().describe("should be the distance for Move, or the y coord of the target for Attack")
            
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
     - 0: +x
     - 1: -x
     - 2: +y
     - 3: -y

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