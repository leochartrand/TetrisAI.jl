import GameZero: rungame
using ProgressBars
using JSON

import TetrisAI: Game, MODELS_PATH
import TetrisAI.Agent: AbstractAgent

using Flux
using Flux: onehotbatch
using Flux.Data: DataLoader
using Flux.Losses: logitcrossentropy

# SHould be refactored
const DATA_PATH = joinpath(TetrisAI.PROJECT_ROOT, "data")
const STATES_PATH = joinpath(DATA_PATH, "states")
const LABELS_PATH = joinpath(DATA_PATH, "labels")

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
    rungame("src/collect_data.jl")
end

"""
Train model on generated training data
"""
function pretrain_agent(lr::Float64 = 1e-3, batch_size::Int64 = 100, epochs::Int64 = 30)

    states = []
    labels = []

    # Ignore hidden files
    states_files = [joinpath(STATES_PATH, file) for file in readdir(STATES_PATH) if startswith(file, ".") == false]
    labels_files = [joinpath(LABELS_PATH, file) for file in readdir(LABELS_PATH) if startswith(file, ".") == false]

    for file in states_files
        line = readline(file)
        state = JSON.parse(JSON.parse(line))["state"]

        append!(states, state)
        # append!(states, JSON.parse(readline(file)))
    end

    for file in labels_files
        line = readline(file)
        action = JSON.parse(JSON.parse(line))["action"]
        action = onehotbatch(action, 1:7)

        append!(labels, action)
        # append!(states, JSON.parse(readline(file)))
    end

    println(labels[1:3])

    # Minus 1 for .gitkeep
    states = reshape(states, :, 1, length(readdir(STATES_PATH)) - 1)
    labels = reshape(labels, :, 1, length(readdir(STATES_PATH)) - 1)
    println(size(labels))

    train_loader = DataLoader((states, labels), batchsize = batch_size, shuffle = true)

    model = TetrisAI.Model.linear_QNet(258, 7)

    loss = logitcrossentropy

    pred = model(states[:, 1, 1])
    println(pred)

    l = loss(pred, labels[:, 1, 1])
    println(l)

    ps = Flux.params(model) # model's trainable parameters

    opt = ADAM(lr)

    iter = ProgressBar(1:epochs)
    set_description(iter, "Pre-training the model on $epochs epochs:")

    for _ in iter
        for (x, y) in train_loader
            gs = Flux.gradient(ps) do
                    ŷ = model(x)
                    loss(ŷ, y)
                end

            Flux.Optimise.update!(opt, ps, gs)
        end
    end

end

function train_agent(agent::AbstractAgent; N::Int=100)

    # Creating the initial game
    game = TetrisGame()

    iter = ProgressBar(1:N)
    set_description(iter, "Training the agent on $N games:")

    for _ in iter
        done = false

        while !done
            done = train!(agent, game)
        end
    end

    @info "Agent high score after $N games => $(agent.record) pts"
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
