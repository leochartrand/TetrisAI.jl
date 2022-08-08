#init 
using TetrisAI

global game = TetrisGame()
global Paused = false
global input = :nothing
global GUI = TetrisUI()
global states = [Int[]]
global labels = [Int[]]
global index = 0

WIDTH = 1000
HEIGHT = 1000

"""
Checks for keyboard input.
"""
function on_key_down(g::Game, k)
    global game, Paused, input
    # Pause, debug and quit
    if k == Keys.P
        if game.is_over
            # Writes training_data to file
            
            # Resets the game when game is over
            reset!(game)
            input = :nothing
        else
            # Pauses or unpauses the game
            Paused = !Paused
        end
    end
    if k == Keys.D
        # Debug print
        println(game)
    end
    if k == Keys.Q
        # Quits the game (exits the julia environment)
        exit()
    end
    # Tetris Input
    if !Paused && !game.is_over
        if (k == Keys.LEFT)
            input = :move_left
        elseif (k == Keys.RIGHT)
            input = :move_right
        elseif (k == Keys.UP || k == Keys.X)
            input = :rotate_clockwise
        elseif (k == Keys.DOWN)
            input = :rotate_counter_clockwise
        elseif (k == Keys.SPACE)
            input = :hard_drop
        elseif (k == Keys.LSHIFT || k == Keys.C)
            input = :hold_piece
        end
    end
end

function save_training_data()
    global states, labels
    # Iterate over states[] and labels[]
        # For each in array, touch and write to file
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
    global game, Paused, input, agent, states, labels, index
    if !Paused && !game.is_over
        # Get old state
        old_state = get_state(game)
        # Sends input and get new state
        send_input!(game, input)
        reward, done, score = tick!(game)
        new_state = get_state(game)
        # Get one hot vector representation of input
        action = TetrisAI.Game.convert_input_to_vector(input)
        # Save training data
        push!(states, old_state)
        push!(labels, action)
        index += 1
        # Reset input for next tick
        input = :nothing
        # Check for constant input for soft drop
        if g.keyboard.Z || g.keyboard.LCTRL 
            send_input!(game, :nothing)
            tick!(game)
        end
    end
end
