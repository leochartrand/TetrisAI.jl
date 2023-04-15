import GameZero: rungame
using ProgressBars
using CUDA 
using Plots
import Flux: gpu, cpu
using JSON
using Dates

import TetrisAI: Game, MODELS_PATH
import TetrisAI.Agent: AbstractAgent


# SHould be refactored
const DATA_PATH = joinpath(TetrisAI.PROJECT_ROOT, "data")
const STATES_PATH = joinpath(DATA_PATH, "states")
const LABELS_PATH = joinpath(DATA_PATH, "labels")

if CUDA.functional()
    CUDA.allowscalar(false)
    device = gpu
else
    device = cpu
end

function play_tetris()
    rungame("src/play.jl")
end

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

function collect_data()
    t2 = Threads.@spawn process_data()
    t1 = Threads.@spawn rungame("src/collect_data.jl")
    wait(t1)
    set_game()
    wait(t2)
end

function get_data()
    download_data()
end

"""
Train model on generated training data
"""
function pretrain_agent(
    agent::AbstractAgent,
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)
    clone_behavior!(agent,lr,batch_size,epochs)
end

function train_agent(agent::AbstractAgent; N::Int=100, limit_updates::Bool=true)

    # Creating the initial game
    game = TetrisGame()

    train!(agent, game, N, limit_updates)
end

function save_agent(agent::AbstractAgent, name::AbstractString=nothing)

    if isfile(joinpath(MODELS_PATH, "$name.bson"))
        @error "file named $name.bson already exists."
        return
    end

    save(agent,name)
end

function load_agent(name::AbstractString) 

    agent = load(name)

    return agent
end
