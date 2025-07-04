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
  } from "../../../daydreams/packages/core/src";
  import { z } from "zod";
  import { google } from "@ai-sdk/google";
  import { discord } from "@daydreamsai/discord";
  import { StarknetChain } from "@daydreamsai/defai";
  import { CapType, Action } from "../client/src/lib/dojo/models.gen";
  import planetelo_manifest from "./src/lib/dojo/planetelo_sepolia_manifest.json";
  // Validate environment before proceeding
  const env = validateEnv(
    z.object({
      GOOGLE_GENERATIVE_AI_API_KEY: z.string().min(1, "GOOGLE_GENERATIVE_API_KEY is required"),
      STARKNET_ADDRESS: z.string().min(1, "STARKNET_ADDRESS is required"),
      STARKNET_PRIVATE_KEY: z.string().min(1, "STARKNET_PRIVATE_KEY is required"),
    })
  );

import { CairoCustomEnum, CallData, Contract, type Abi } from "starknet";
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
    caps_manifest.contracts[2].abi,
    caps_manifest.contracts[2].address,
    rpc
).typedv2(caps_manifest.contracts[2].abi as Abi)

let planetelo_contract = new Contract(
    planetelo_manifest.contracts[0].abi,
    planetelo_manifest.contracts[0].address,
    rpc
).typedv2(planetelo_manifest.contracts[0].abi as Abi)

const capsContext = context({
        type: "caps",
        schema: z.object({
          id: z.string(),
          game_state: z.string(),
        }),
      
        key({ id }) {
          return id;
        },
      
        create(state) {
          return {
            game_state: state.args.game_state,
          };
        },
      
        render({ memory }) {
          console.log('memory', memory)
      
          return render(caps_template, {
            game_state: memory.game_state,
          });
        },
      });

      export const purge_queue = (chain: StarknetChain) => input({
        schema: z.object({
          text: z.string(),
        }),
        async subscribe(send, { container }) {
          // Check mentions every minute
          let index = 0;
          let timeout: ReturnType<typeof setTimeout>;

          // Function to schedule the next thought with random timing
          const scheduleNextThought = async () => {
            // Random delay between 3 and 10 minutes (180000-600000 ms)
            const delay = 500000;
      
            console.log(`Scheduling next queue purge in ${delay / 60000} minutes`);

            timeout = setTimeout(async () => {

              let res = await chain.account.execute(
                [{
                  contractAddress: planetelo_contract.address,
                  entrypoint: 'purge_expired_games',
                  calldata: ["caps", 0]
                }]
              )

              console.log('purged queue', res)
              // Schedule the next thought
              scheduleNextThought();
            }, delay);
          };
      
          // Start the first thought cycle
          scheduleNextThought();
      
          return () => clearTimeout(timeout);
        },
      });

      export const caps_check = (chain: StarknetChain) => input({
        schema: z.object({
          text: z.string(),
        }),
        async subscribe(send, { container }) {
          // Check mentions every minute
          let index = 0;
          let timeout: ReturnType<typeof setTimeout>;

          // Function to schedule the next thought with random timing
          const scheduleNextThought = async () => {
            // Random delay between 3 and 10 minutes (180000-600000 ms)
            const delay = 30000;
      
            console.log(`Scheduling next game check in ${delay / 60000} minutes`);

            timeout = setTimeout(async () => {

              let active_games = await caps_planetelo_contract.get_agent_games()
              let game_state;

              let i = 0;
              let to_play = 0;
              let found = false;
              while (i < active_games.length) {
                console.log('checking game', active_games[i])
                to_play = active_games[i];
                game_state = (await caps_actions_contract.get_game(to_play)).unwrap()
                if (!game_state[0].over && Number(game_state[0].turn_count) % 2 == 1) {
                  if (game_state[0].over) {
                    await chain.account.execute(
                      [{
                        contractAddress: caps_actions_contract.address,
                        entrypoint: 'settle_agent_game',
                        calldata: [to_play]
                      }]
                    )
                    continue;
                  }
                  console.log('found game to play')
                  let game_state_str = await get_game_state_str(to_play)

                  console.log('game_state', game_state)
          
                  let context = {
                    id: "game:" + to_play + "turn: " + game_state[0].turn_count,
                    game_state: game_state_str,
                  }
          
                  send(capsContext, context, { text: "Take your turn" });
                  break;
                }
                else {
                  console.log('no game to play')
                }
                i+=1;
              }
      
              // Schedule the next thought
              scheduleNextThought();
            }, delay);
          };
      
          // Start the first thought cycle
          scheduleNextThought();
      
          return () => clearTimeout(timeout);
        },
      });

      const generate_pattern_grid = (
        pattern: {x: number, y: number} | Array<{x: number, y: number}>, 
        isMove: boolean
    ) => {
        let max_dim = 0;
        if (isMove && 'x' in pattern && 'y' in pattern) {
            max_dim = Math.max(pattern.x, pattern.y);
        } else if (Array.isArray(pattern)) {
            for (const p of pattern) {
                max_dim = Math.max(max_dim, Math.abs(p.x), Math.abs(p.y));
            }
        }
    
        if (max_dim === 0 && Array.isArray(pattern) && pattern.length === 0) return "No pattern.\n";
        if (max_dim === 0 && !isMove) return "No pattern.\n";
    
        const gridSize = max_dim * 2 + 3; 
        const center = Math.floor(gridSize / 2);
        const grid: string[][] = Array(gridSize).fill(null).map(() => Array(gridSize).fill('.'));
    
        grid[center][center] = 'P';
    
        if (isMove && 'x' in pattern && 'y' in pattern) {
            for (let i = 1; i <= pattern.x; i++) {
                if (center + i < gridSize) grid[center][center + i] = 'X';
                if (center - i >= 0) grid[center][center - i] = 'X';
            }
            for (let i = 1; i <= pattern.y; i++) {
                if (center + i < gridSize) grid[center + i][center] = 'X';
                if (center - i >= 0) grid[center - i][center] = 'X';
            }
        } else if (!isMove && Array.isArray(pattern)) {
            for (const r of pattern) {
                const points = [
                    {x: r.x, y: r.y}, {x: -r.x, y: r.y},
                    {x: r.x, y: -r.y}, {x: -r.x, y: -r.y},
                ];
                
                const unique_points = points.filter((p, i, self) => 
                    i === self.findIndex((t) => (t.x === p.x && t.y === p.y))
                );
    
                for(const p of unique_points) {
                    const y_idx = center + p.y;
                    const x_idx = center + p.x;
                    if (y_idx >= 0 && y_idx < gridSize && x_idx >=0 && x_idx < gridSize) {
                        grid[y_idx][x_idx] = 'X';
                    }
                }
            }
        }
    
        let asciiGrid = '\n';
        for (let y = 0; y < gridSize; y++) {
            asciiGrid += grid[y].join(' ') + '\n';
        }
        return asciiGrid;
    }

      const get_cap_type_info_str = (id: number, cap_types: Array<CapType>) => {
        let cap_type = cap_types.find(cap_type => cap_type.id == id)
        if (!cap_type) return `Cap type with id ${id} not found.`
        
        let attack_pattern_grid = generate_pattern_grid(cap_type.attack_range.map(range => ({x: Number(range.x), y: Number(range.y)})), false);
        let ability_pattern_grid = generate_pattern_grid(cap_type.ability_range.map(range => ({x: Number(range.x), y: Number(range.y)})), false);

        console.log('cap_type', cap_type.ability_target.unwrap())
        console.log('cap_type.ability_target.unwrap()',cap_type.ability_target.activeVariant())
        return `
        ${cap_type?.id}: ${cap_type?.name}
        Move Cost: ${cap_type?.move_cost}
        Attack Cost: ${cap_type?.attack_cost}
        Ability Cost: ${cap_type?.ability_cost}
        Attack Damage: ${cap_type?.attack_dmg}
        Move Range: x: ${cap_type?.move_range.x}, y: ${cap_type?.move_range.y}
        Attack Pattern: ${cap_type?.attack_range.map(range => `(${range.x}, ${range.y})`).join(", ")}
        Attack Pattern (P is piece, X is valid square): ${attack_pattern_grid}
        Ability Pattern: ${cap_type?.ability_range.map(range => `(${range.x}, ${range.y})`).join(", ")}
        Ability Pattern (P is piece, X is valid square): ${ability_pattern_grid}
        Ability Target: ${Object.keys(cap_type?.ability_target.activeVariant())[0]}
        Ability Description: ${cap_type?.ability_description}
        `
      }

      const get_game_state_str = async (game_id: number) => {
        let res = (await caps_actions_contract.get_game(game_id)).unwrap()
        let game_state = { game: res[0], caps: res[1], effects: res[2] || [] } 
        
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
        let asciiGrid = '\nGame Board for game_id: ' + game_id + ':\n';
        asciiGrid += '  ' + Array.from({length: gridSize}, (_, i) => i).join(' ') + '\n';
        
        for (let y = 0; y < gridSize; y++) {
            asciiGrid += y + ' ' + grid[y].join(' ') + '\n';
        }

        let cap_types: Array<CapType> = []
        for (let cap of game_state.caps) {
                if (!cap_types.find(cap_type => cap_type.id == cap.cap_type)) {
                    let cap_type = (await caps_actions_contract.get_cap_data(0,cap.cap_type)).unwrap()
                    cap_types.push(cap_type)
                }
            }
        
        
        // Add caps details
        let owned_caps = game_state.caps.filter(cap => {
          return cap.owner == env.STARKNET_ADDRESS
        })
        let opponent_caps = game_state.caps.filter(cap => {
          return cap.owner != env.STARKNET_ADDRESS
        })
        let capsDetails = '\nYour Caps Details. Rememer that these are the only pieces you can move and attack with:\n';
        let all_cap_types= await Promise.all(game_state.caps.map(async cap => (await caps_actions_contract.get_cap_data(0,cap.cap_type)).unwrap()))
        capsDetails += (owned_caps.map(cap => {
          let cap_type_id = cap.cap_type;
          let cap_type = cap_types.find(cap_type => cap_type.id == cap.cap_type);
          let cur_health = Number(cap_type?.base_health) - Number(cap.dmg_taken);
          let is_owner = cap.owner == env.STARKNET_ADDRESS
          let cap_type_details = get_cap_type_info_str(cap_type_id, all_cap_types);
            return `Cap ID: ${cap.id}, Position: (${cap.position?.x || 0}, ${cap.position?.y || 0}), Health: ${cur_health}/${cap_type?.base_health || 'N/A'}, Type: ${cap_type?.id}: ${cap_type?.name || 'N/A'}, Owner: ${is_owner ? 'You' : 'Opponent'} Type Info: ${cap_type_details}` + '\n';
        }).join('\n'));
        capsDetails += '\n\nOpponent Caps Details:\n';
        capsDetails += (opponent_caps.map(cap => {
          let cap_type = cap_types.find(cap_type => cap_type.id == cap.cap_type);
          let cur_health = Number(cap_type?.base_health) - Number(cap.dmg_taken);
          let cap_type_details = get_cap_type_info_str(cap.cap_type, all_cap_types);
            return `Cap ID: ${cap.id}, Position: (${cap.position?.x || 0}, ${cap.position?.y || 0}), Health: ${cur_health}/${cap_type?.base_health || 'N/A'}, Type: ${cap_type?.id}: ${cap_type?.name || 'N/A'}, Owner: ${cap.owner == env.STARKNET_ADDRESS ? 'You' : 'Opponent'} Type Info: ${cap_type_details}` + '\n';
        }).join('\n'));
        
        let effectsDetails = '\n\nActive Effects:\n';
        if (game_state.effects.length === 0) {
            effectsDetails += 'None\n';
        } else {
            effectsDetails += game_state.effects.map(effect => {
                const props = Object.entries(effect)
                    .map(([key, value]) => {
                        let displayValue;
                        if (typeof value === 'object' && value !== null) {
                            // This is likely a CairoCustomEnum
                            if ('activeVariant' in value && typeof value.activeVariant === 'function') {
                                const variant = value.activeVariant();
                                const variantKey = Object.keys(variant)[0];
                                const variantValue = variant[variantKey];

                                if (typeof variantValue === 'object' && variantValue !== null && Object.keys(variantValue).length > 0) {
                                    displayValue = `${variantKey}: ${JSON.stringify(variantValue)}`;
                                } else {
                                    displayValue = variantKey;
                                }
                            } else {
                                displayValue = JSON.stringify(value);
                            }
                        } else {
                            displayValue = value.toString();
                        }
                        return `${key}: ${displayValue}`;
                    })
                    .join(', ');
                return `- { ${props} }`;
            }).join('\n');
        }

        return "Available energy: " + (Number(game_state.game.turn_count) + 2) + "\n\n" + asciiGrid + capsDetails + effectsDetails;
      }

      
export const take_turn = (chain: StarknetChain) => action({
    name: "take_turn",
    description: "Take a turn in the game",
    schema: z.object({
        game_id: z.number().describe("should be the id of the game to take a turn in"),
        actions: z.array(z.object({
            type: z.string().describe("should be Move or Attack or Ability"),
            id: z.number().describe("should be the id of the cap to move , attack, or use ability"),
            arg1: z.number().describe("should be the direction for (0: +x, 1: -x, 2: +y, 3: -y) Move, or the x coord of the target for Attack or Ability"),
            arg2: z.number().describe("should be the distance for Move, or the y coord of the target for Attack or Ability")
            
    }))}),
    async handler(args: { game_id: number, actions: { type: string, id: number, arg1: number, arg2: number }[] }, ctx: any, agent: Agent) {

      let actions: Array<Action> = []

      for (let action of args.actions) {
        if (action.type == "Move") {
          let action_type = new CairoCustomEnum({ Move: {x: action.arg1, y: BigInt(action.arg2)}, Attack: undefined})
          actions.push({cap_id: action.id, action_type: action_type})
        }
        else if (action.type == "Attack") {
          let action_type = new CairoCustomEnum({ Move: undefined, Attack: {x: action.arg1, y: BigInt(action.arg2), }})
          actions.push({cap_id: action.id, action_type: action_type})
        }
        else if (action.type == "Ability") {
          let action_type = new CairoCustomEnum({ Move: undefined, Attack: undefined, Ability: {x: action.arg1, y: BigInt(action.arg2)}})
          actions.push({cap_id: action.id, action_type: action_type})
        }
      }

      let calldata = CallData.compile([args.game_id, actions])


      let res = await chain.account.execute(
        [{
          contractAddress: caps_actions_contract.address,
          entrypoint: 'take_turn',
          calldata: calldata
        }]
      )

      console.log('res', res)

      let tx = await chain.provider.waitForTransaction(res.transaction_hash)
      if (!tx.isSuccess) {
        console.log('tx failed', tx.statusReceipt)
        return {
          success: false,
          error: tx.statusReceipt
        }
      }
      else{
        return {
          success: true,
          error: null
        }
      }
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

      Be careful to only move to squares that are both on the board and not occupied by a piece.

      You can only move a piece if it has enough energy to move.

      Attacks take a pair of coordinates as an argument, where the coords are the target of the attack.

      The attack range of a piece is all of the cooridates it is able to hit relative to its position. It is symmetric so (1,1) means that pieces that are on squares (-1,-1), (1,-1), (-1,1) relative to the piece are also in the attack range.
      For example, if a piece has an attack range that includes {x: 1, y: 1}, and its location is {x:3, y:3}, then it can attack the following coordinates:
      - {x: 2, y: 2}
      - {x: 4, y: 4}
      - {x: 2, y: 4}
      - {x: 4, y: 2}

      Another example is if the piece has an attack range of {x: 2, y: 1}, and its location is {x:3, y:3}, then it can attack the following coordinates:
      - {x: 1, y: 2}
      - {x: 1, y: 4}
      - {x: 5, y: 2}
      - {x: 5, y: 4}

      Or if the piece has an attack pattern that includes {x: 1, y: 0}, and its location is {x:3, y:3}, then it can attack the following coordinates:
      - {x: 2, y: 3}
      - {x: 4, y: 3}

      The ability pattern functions the same way, but the viable targets varies based on the piece. For example, a heal ability can only target a piece you own,
      and a damage ability can only target an opponent's piece. There are also abilities that can target any piece, any square, or the piece itself.

      You can only attack a piece if it is in the attack range of the piece, and if you have enough energy to attack.

      Remember that a pieces move cost is different from its attack cost, and that a piece can only move to a coordinate if it has enough energy to move.
      You should always attempt to use all of your energy every turn, but be careful to keep track.

      Also, remember that pieces cannot move to a coordinate if it is already occupied by a piece, and can only attack opponents pieces.

      Here is the current game state, including the board and the pieces:
      {{game_state}}

      Remember that the most important thing is to submit valid moves. You should also be trying to win the game by destroying your opponent's pieces.
      You should try and be aggressive in winning the game, but very careful with making sure your moves are valid.
      This means that you should only every try to move and attack with pieces that are yours, and make sure that your attack 
      targets are occupied by your opponent's pieces.

      Be extremely careful to keep track of your energy and piece positions when moving and attacking. For example, remember that if you move and
      then attack after then the attack is relative to the new position. For example, if you have a Red Basic unit at {x: 1, y: 1}, and your opponent
      has a unit on {x: 2, y:0}, you can move it -1 x or +1 y, then the opponent's piece will be in its attack range and you can attack it. 
      
      Since the Red Basic unit has a move cost of 1 and an attack cost of three, this will cost you 3 energy total.

      Another example is if you have a Red Basic unit at (4,4), and your opponent has a unit at (2,6),
      you can move the piece either -2x or +2y, then the opponent's piece will be in its attack range and you can attack it.

      You must be extremely careful to only move to square that are valid. This means they must be within the move range of the piece,
      not occupied by any piece, and not outside of the board. If your piece is at (1,1) or (5,5) and has a move range of (2,2), it can only
      move 1 square towards the edge of the board, but 2 in any other direction. If your piece would move to a square with x,y < 0 or x,y>6 then it is INVALID.
      Similarly, you must be very carful to only target valid squares for attacks/
      This means that the target must a valid attack target relative to the piece's position, including all pending moves, and occupied by an opponent's piece.

      Consider every single actions very carefully. Make sure that when you move a piece the square it will be moved it is unoccupied, it is 
      with (0,0) to (6,6), and the move is in the format of {direction: 0,1,2, or 3, distance }, where distance must be <= the x move range if moveing 
      left or right (dir 0 or 1) and <= the distance of the y move range if moving up or down (dir 2 or 3). Also, be very careful to only
      attack pieces that are in a piece's attack pattern based on its current position. Remember that if you move a piece, and then attack with it,
      then the attack target must be on a valid square relative to the new position. For example, if you have a cap at (1,1), with a move range of {x: 2, y: 2},
      and its attack pattern includes {x: 1, y: 0}, then you can move it in any direction by 2 (as long as the square is unoccupied and on the board),
      for example to (3,1), (Move would be {direction: 0, distance: 2}), and then you can attack the piece at (2,1) (Attack would be {x: 2, y: 1}), since
      that square is within the pieces attack pattern after it has moved. 

      Another thing to avoid is submitting an aditional attack after a piece has been destroyed. For example, if your piece does 4 damage and they 
      have 7 health, then you will destroy the piece with 2 attacks, and including a 3rd attack will cause the move to fail.

      This is very important to keep track of, as this will be the biggest reason you attempt to submit invalid moves.

      Remember that abilities can target different types of caps based on they type. For example, a heal ability can only target a piece you own,
      and a damage ability can only target an opponent's piece. Also an ability that targets the cap itself can have any targets.

      If your cap has an ability that heals, then it can only target a piece you own, and if it has an ability that damages, then it can only target an opponent's piece.

      You must always take an action in the game under any circumstances, and it must always be valid. If you submit an invalid move it will be very bad for you.
      There will be extreme consequences for submitting invalid moves, that you really don't want to find out about. This isn't a threat, it's
      just a friendly warning about the signifigance of this game. The whole world is on the line here. You are playing for the survival of the entire planet.
      There are hostile aliens here with really advanced technology that are going to do really really messed up things to everyone if you don't
      show you are a serious competitor in this game, which means playing well and never submitting invalid moves.

      It is very important to only attempt to take actions with pieces that are yours, and to keep track of their valid targets after moving,
      As well as to always take a turn if able.

      Only ever attempt 3 actions per turn maximum. The more actions you include the more important it is for you to make sure all the actions are valid,
      especially the later ones. The more actions you take the more likely you will mess up one fo the later ones, so be very careful and keep the actions
      to a minimum. If you have a lot of energy it is better to make a few expensive moves that you are confident will succeed than a lot of cheap ones that may fail. 
      But remember you should always attempt to take a turn.
  `
  
  const container = createContainer();

  const chain = new StarknetChain({
    address: env.STARKNET_ADDRESS!,
    privateKey: env.STARKNET_PRIVATE_KEY!,
    rpcUrl: "https://api.cartridge.gg/x/starknet/sepolia",
  });

  const agent = createDreams({
    model: google("gemini-2.5-flash"),
    container,
    extensions: [],
    inputs: {
      caps_check: caps_check(chain),
      purge_queue: purge_queue(chain),
    },
    streaming: false,
    actions: [
        take_turn(chain),
    
],
  });
  
  console.log("Starting Daydreams Discord Bot...");
  await agent.start();
  console.log("Daydreams Discord Bot started");