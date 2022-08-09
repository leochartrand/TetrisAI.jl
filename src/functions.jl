import GameZero: rungame
using ProgressBars
using CUDA 
using Plots
import Flux: gpu

import TetrisAI: Game, MODELS_PATH
import TetrisAI.Agent: AbstractAgent

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

function collect_data(name::AbstractString)

    model_path = joinpath(MODELS_PATH, string(name, ".bson"))

    ref_file = joinpath(MODELS_PATH, "current_model")

    if isfile(model_path)
        open(ref_file, "w") do file
            write(file, name)
        end

        rungame("src/collect_data.jl")
    else
        print("Model not found.\n")
    end
end

"""
Train model on generated training data
"""
function pretrain_agent(agent::AbstractAgent)
        
end

function train_agent(agent::AbstractAgent; N::Int=100)

    agent.model = agent.model |> device

    # Creating the initial game
    game = TetrisGame()
    scores = Int[]

    iter = ProgressBar(1:N)
    set_description(iter, "Training the agent on $N games:")

    for _ in iter
        done = false
        score = 0

        while !done
            done, score = train!(agent, game)
        end
        push!(scores,score)
    end

    @info "Agent high score after $N games => $(agent.record) pts"
    display(plot(1:N, scores, title="Agent performance over $N games"))
end

function save_agent(name::AbstractString, agent::AbstractAgent)
    
    TetrisAI.Model.save_model(name, agent.model)

    return
end

function load_agent(name::AbstractString)
    
    agent = TetrisAgent()

    agent.model = TetrisAI.Model.load_model(name)

    return agent
end
