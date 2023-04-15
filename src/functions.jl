import GameZero: rungame
using ProgressBars
using CUDA 
using Plots
import Flux: gpu, cpu
using JSON
using Dates

import TetrisAI: Game, MODELS_PATH
import TetrisAI.Agent: AbstractAgent

include("benchmark.jl")


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

"""
    play_tetris()


Play using Tetris' interface
"""
function play_tetris()
    rungame("src/play.jl")
end

"""
    model_demo(name::AbstractString)

Run a model game
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

Play using the Tetris' interface and upload the game data to AWS S3 Bucket
"""
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
    pretrain_agent(
    agent::AbstractAgent,
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)

Train model on generated training data
"""
function pretrain_agent(
    agent::AbstractAgent,
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)
    clone_behavior!(agent,lr,batch_size,epochs)
end

function train_agent(agent::AbstractAgent; N::Int=100, run_id::String="", limit_updates::Bool=true, render::Bool=true)
    benchmark = ScoreBenchMark(n=N)

    update_rate::Int64 = 1
    if limit_updates
        update_rate = max(round(N * 0.05), 1)
    end

   to_device!(agent)

    # Creating the initial game
    game = TetrisGame()

    iter = ProgressBar(1:N)
    set_description(iter, "Training the agent on $N games:")

    for _ in iter
        done = false
        score = 0
        nb_ticks = 0
        while !done
            done, score = train!(agent, game)
            nb_ticks = nb_ticks + 1
            if nb_ticks > 20000
                break
            end
        end

        append_score_ticks!(benchmark, score, nb_ticks)
        update_benchmark(benchmark, update_rate, iter, render)
    end

    if isempty(run_id)
        prefix = agent.type
        suffix = Dates.format(DateTime(now()), "yyyymmddHHMMSS")
        run_id = "$prefix-$suffix"
    end

    save_to_csv(benchmark, run_id * ".csv")
    

    @info "Agent high score after $N games => $(agent.record) pts"
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
