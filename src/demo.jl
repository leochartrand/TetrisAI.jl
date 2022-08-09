#init 
using TetrisAI
using CUDA 
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

global model_name = ""

open(joinpath(MODELS_PATH, "current_model"), "r") do file
    global model_name = readline(file)
end

global agent = load_agent(model_name)
agent.model = agent.model |> device

WIDTH = 1000
HEIGHT = 1000

"""
Checks for keyboard input.
"""
function on_key_down(g::Game, k)
    global game, Paused
    # Pause, debug and quit
    if k == Keys.P 
        #Pauses or unpauses the game
        Paused = !Paused
    end
    if k == Keys.D
        # Debug print
        println(game)
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
    global game, Paused, GUI
    TetrisAI.GUI.drawUI(GUI,game,Paused)
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
        reset!(game)
    end
end
