// Router configuration with game_id parameters - tentacle routing time! 🐙
import Home from './routes/Home.svelte'
import GameView from './routes/GameView.svelte'

export const routes = {
  // Home route - shows matchmaking and general interface
  '/': Home,
  
  // Game route with game_id parameter
  '/game/:game_id': GameView,
  
  // Fallback route
  '*': Home,
}
