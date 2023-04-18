import GameZero: rungame
using ProgressBars
using CUDA 
using Plots
import Flux: gpu, cpu
using JSON
using Dates
using DataStructures

import TetrisAI: Game, MODELS_PATH
import TetrisAI.Agent: AbstractAgent

"""
    play_tetris()

Play using the Tetris' interface
"""
function play_tetris()
    rungame("src/play.jl")
end

"""
    model_demo(name::AbstractString)

Run a model game.
"""
function model_demo(name::AbstractString)

    model_path = joinpath(MODELS_PATH, string(name, ".bson"))

    ref_file = joinpath(MODELS_PATH, "current_model")

    if isfile(model_path)
        open(ref_file, "w") do file
            write(file, name)
        end

        rungame("src/demo.jl")
    else
        print("Model not found.\n")
    end
end

"""
    collect_data()

Play using the Tetris' interface and upload the game data to AWS S3 Bucket.
Make use of two threads to avoid wait time at the end of a game:
1. Thread to run the gameplay
2. Thread that uploads the game's data to the AWS S3 Bucket.
"""
function collect_data()
    t2 = Threads.@spawn process_data()
    t1 = Threads.@spawn rungame("src/collect_data.jl")
    wait(t1)
    set_game()
    wait(t2)
end

"""
    pretrain_agent(
        agent::AbstractAgent,
        lr::Float64 = 5e-4, 
        batch_size::Int64 = 50, 
        epochs::Int64 = 80)

Train model on generated training data.
"""
function pretrain_agent(
    agent::AbstractAgent,
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)
    clone_behavior!(agent,lr,batch_size,epochs)
end

"""
    train_agent(agent::AbstractAgent; N::Int=100, limit_updates::Bool=true, render::Bool=true, run_id::String="")

TBW
"""
function train_agent(agent::AbstractAgent; N::Int=100, limit_updates::Bool=true, render::Bool=true, run_id::String="")

    # Creating the initial game
    game = TetrisGame()

    train!(agent, game, N, limit_updates, render, run_id)
end

"""
    save_agent(agent::AbstractAgent, name::AbstractString=nothing)

TBW
"""
function save_agent(agent::AbstractAgent, name::AbstractString=nothing)

    if isfile(joinpath(MODELS_PATH, "$name.bson"))
        @error "file named $name.bson already exists."
        return
    end

    save(agent,name)
end

"""
    load_agent(name::AbstractString)

TBW
"""
function load_agent(name::AbstractString) 

    agent = load(name)

    return agent
end
