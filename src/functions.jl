import GameZero: rungame
using ProgressBars
using CUDA 
using Plots
import Flux: gpu, cpu
using JSON

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

    graph_steps = round(N / 10)
    update_rate::Int64 = 1
    if limit_updates
        update_rate = max(round(N * 0.05), 1)
    end

   to_device!(agent)

    # Creating the initial game
    game = TetrisGame()
    scores = Int[]
    ticks = Int[]

    iter = ProgressBar(1:N)
    set_description(iter, "Training the agent on $N games:")

    for i in iter
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

        push!(scores, score)
        push!(ticks, nb_ticks)

        if (i % update_rate) == 0
            plot(1:i,
                [scores, ticks],
                xlims=(0, N),
                xticks=0:graph_steps:N,
                ylims=(0, max(findmax(scores)[1], findmax(ticks)[1])),
                title="Agent performance over $N games",
                linecolor = [:orange :blue],
                linewidth = 2,
                label=["Scores" "Nombre de ticks"])
            xlabel!("Itérations")
            ylabel!("Score")
            display(plot!(legend=:outerbottom, legendcolumns=2))
        end
    end


    @info "Agent high score after $N games => $(agent.record) pts"
end

function save_agent(agent::AbstractAgent, name::AbstractString)

    save(agent,name)
end

function load_agent(agent::AbstractAgent, name::AbstractString) 
    # might have to use kwargs... to account for cases where agent has more than 1 model (i.e. policy gradients)

    load!(agent, name)

    return agent
end