using BSON, NNlib, Dates

# AbstractAgent interface
abstract type AbstractAgent end

Base.@kwdef mutable struct RandomAgent <: AbstractAgent
    type::String = "RANDOM"
    n_games::Int = 0
    record::Int = 0
    model = TetrisAI.Model.random_Net(7)
end

function Base.show(io::IO, agent::AbstractAgent)
    println("n_games => ", agent.n_games)
    println("record => ", agent.record)
end

function get_action(agent::AbstractAgent, nb_outputs::Integer=7)
    final_move = zeros(Int, nb_outputs)
    move = rand(1:nb_outputs)
    final_move[move] = 1

    return final_move
end

function train!(agent::AbstractAgent, game::TetrisAI.Game.AbstractGame)

    # Get the current step
    old_state = TetrisAI.Game.get_state(game)

    # Get the predicted move for the state
    move = get_action(agent, old_state)
    TetrisAI.send_input!(game, move)

    # Play the step
    _, done, score = TetrisAI.Game.tick!(game)

    if done
        # Reset the game
        TetrisAI.Game.reset!(game)
        agent.n_games += 1

        if score > agent.record
            agent.record = score
        end
    end

    return done, score
end

function to_device!(agent::AbstractAgent) end

function clone_behavior!(agent::AbstractAgent, lr::Float64 = 5e-4, batch_size::Int64 = 50, epochs::Int64 = 80) end


# Util functions

"""

"""
function save(agent::AbstractAgent, name::AbstractString=nothing)

    if isnothing(name)
        prefix = agent.type
        suffix = Dates.format(DateTime(now()), "yyyymmddHHMMSS")
        name = "$prefix-$suffix"
    end

    file = string(name, ".bson")

    path = joinpath(MODELS_PATH, file)
    
    BSON.@save path agent
    
    return
end

function load(name::AbstractString)
    
    file = string(name, ".bson")

    path = joinpath(MODELS_PATH, file)

    if isfile(path)
        agent = get(BSON.load(path, @__MODULE__), :agent, "Agent_not_found")
    else
        print("Agent not found.\n")
    end

    return agent
end
