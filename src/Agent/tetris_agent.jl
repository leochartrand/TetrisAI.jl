using BSON, NNlib, Dates

# AbstractAgent interface
abstract type AbstractAgent end

Base.@kwdef mutable struct RandomAgent <: AbstractAgent
    type::String = "RANDOM"
    n_games::Int = 0
    record::Int = 0
    model = TetrisAI.Model.random_Net(7)
end

"""
    Base.show(io::IO, agent::AbstractAgent)

Print relevant Agent info.
"""
function Base.show(io::IO, agent::AbstractAgent)
    println("n_games => ", agent.n_games)
    println("record => ", agent.record)
end

"""
    get_action(agent::AbstractAgent; nb_outputs::Integer=7)
"""
function get_action(agent::AbstractAgent; nb_outputs::Integer=7) end

"""
    train!(agent::AbstractAgent, game::TetrisAI.Game.AbstractGame)
"""
function train!(agent::AbstractAgent, game::TetrisAI.Game.AbstractGame) end

"""
    to_device!(agent::AbstractAgent)

Send the Agent's models to cpu/gpu.
"""
function to_device!(agent::AbstractAgent) end

"""
    clone_behavior!(
        agent::AbstractAgent, 
        lr::Float64 = 5e-4, 
        batch_size::Int64 = 50, 
        epochs::Int64 = 80)

Train an agent on labeled expert data.
"""
function clone_behavior!(
    agent::AbstractAgent, 
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80) end


# Util functions

"""
    save(agent::AbstractAgent, name::AbstractString=nothing)

Save an agent to file in BSON format.
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

"""
    load(name::AbstractString)

Load an agent from a BSON file.
"""
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
