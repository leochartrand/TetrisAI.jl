#init 
using TetrisAI
using CUDA
using DataStructures
import Flux: gpu, cpu

if CUDA.functional()
    CUDA.allowscalar(false)
    device = gpu
else
    device = cpu
end

global game = TetrisGame()
global Paused = false
global GUI = TetrisUI()
global feature_extraction = false

global agent_name = ""

open(joinpath(MODELS_PATH, "current_model"), "r") do file
    global agent_name = readline(file)
end

global agent = load_agent(agent_name)
to_device!(agent)

WIDTH = 1000
HEIGHT = 1000

"""
Checks for keyboard input.
"""
function on_key_down(g::Game, k)
    global game, Paused, feature_extraction
    # Pause, debug and quit
    if k == Keys.P 
        #Pauses or unpauses the game
        Paused = !Paused
    end
    if k == Keys.D
        # Debug print
        println(game)
    end
    if k == Keys.F
        # Debug print
        feature_extraction = !feature_extraction
    end
    if k == Keys.Q
        # Quits the game (exits the julia environment)
        exit()
    end
end

"""
Base GameZero.jl function, called every frame. Draws everything on screen.
"""
function draw(g::Game)
    global GUI, game, Paused, feature_extraction
    TetrisAI.GUI.drawUI(GUI,game,Paused,feature_extraction)
end

"""
Base GameZero.jl function, called every frame. Updates the game state.
"""
function update(g::Game)
    global game, Paused, agent
    if !Paused && !game.is_over

        # Get the current step
        old_state = TetrisAI.Game.get_state(game)
    
        # Get the predicted move for the state
        move = TetrisAI.Agent.get_action(agent, old_state)
        TetrisAI.Game.send_input!(game, move)

        tick!(game)
    end
    if game.is_over
        # Resets the game when game is over
        TetrisAI.Game.reset!(game)
    end
end
