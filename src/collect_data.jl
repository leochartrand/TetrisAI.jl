#init 
using TetrisAI
using JSON
using Dates

const DATA_PATH = joinpath(TetrisAI.PROJECT_ROOT, "data")
const STATES_PATH = joinpath(DATA_PATH, "states")
const LABELS_PATH = joinpath(DATA_PATH, "labels")

global game = TetrisGame()
global Paused = false
global input = :nothing
global GUI = TetrisUI()
global states = []
global labels = []
global index = 0
global json = ".json"

const input_dict = Dict(
    :nothing => 1,   
    :move_left => 2,
    :move_right => 3,
    :hard_drop => 4,
    :rotate_clockwise => 5,
    :rotate_counter_clockwise => 6,
    :hold_piece => 7
)

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
            save_training_data()

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
    arr = []

    suffix = Dates.format(DateTime(now()), "yyyymmddHHMMSS")
    stateFile = "states_" * suffix * json
    actionFile = "actions_" * suffix * json

    stateFileName = joinpath(STATES_PATH, stateFile)
    actionFileName = joinpath(LABELS_PATH, actionFile)

    open(stateFileName, "a") do f
        #for i in eachindex(states)
        for (idx, state) in states
            #println(states[i])
            state = JSON.json(Dict("state$idx" => state))
            push!(arr, state)
        end
        #JSON.print(f, arr, size(states, 1))
        JSON.print(f, arr)
    end

    empty!(arr)
    open(actionFileName, "a") do f
        #for i in eachindex(labels)
        for (idx, label) in labels
            #println(labels[i])
            label = JSON.json(Dict("label$idx" => label))
            push!(arr, label)
        end
    #JSON.print(f, arr, size(labels, 1))
    JSON.print(f, arr)
    end



    #for (idx, state) in states
        # filename = joinpath(STATES_PATH, "G$idx.json")
        # open(filename, "w") do f
        #     JSON.print(f, JSON.json(Dict("state" => state)))
        # end



    #end

    #for (idx, label) in labels
        # filename = joinpath(LABELS_PATH, "G$idx.json")
        # open(filename, "w") do f
        #     JSON.print(f, JSON.json(Dict("action" => label)))
        # end
    #end


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
        
        # Right now we are only interested in non nothing moves
        if input != :nothing
            # Save training data
            state = get_state(game)
            label = input_dict[input]
            push!(states, (index, state))
            push!(labels, (index, label))
            index += 1
        end


        # Sends input and get new state
        send_input!(game, input)
        _, _, _ = tick!(game)

        # Reset input for next tick
        input = :nothing
        # Check for constant input for soft drop
        if g.keyboard.Z || g.keyboard.LCTRL 
            send_input!(game, :nothing)
            tick!(game)
        end
    end
end
