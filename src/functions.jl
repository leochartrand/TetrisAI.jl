import GameZero: rungame
using ProgressBars
using CUDA 
using Plots
import Flux: gpu
using JSON

import TetrisAI: Game, MODELS_PATH
import TetrisAI.Agent: AbstractAgent

using Flux
using Flux: onehotbatch, onecold
using Flux.Data: DataLoader
using Flux.Losses: logitcrossentropy

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
    rungame("src/collect_data.jl")
end

"""
Train model on generated training data
"""
function pretrain_agent(model_name::AbstractString; lr::Float64 = 5e-4, batch_size::Int64 = 50, epochs::Int64 = 80)

    states = Int[]
    labels = Int[]

    # Minus 1 for .gitkeep
    n_files = length(readdir(STATES_PATH)) - 1

    # Ignore hidden files
    states_files = [joinpath(STATES_PATH, file) for file in readdir(STATES_PATH) if startswith(file, ".") == false]
    labels_files = [joinpath(LABELS_PATH, file) for file in readdir(LABELS_PATH) if startswith(file, ".") == false]

    for file in states_files
        line = readline(file)
        state = JSON.parse(JSON.parse(line))["state"]   # oopsie?

        append!(states, state)
    end

    for file in labels_files
        line = readline(file)
        action = JSON.parse(JSON.parse(line))["action"] # god...
        action = onehotbatch(action, 1:7)

        append!(labels, action)
    end

    # Minus 1 for .gitkeep
    states = reshape(states, :, 1, n_files)
    labels = reshape(labels, :, 1, n_files)

    # Homemade split to have at least a testing metric
    train_states = states[:, :, begin:end - 100]
    train_labels = labels[:, :, begin:end - 100]
    test_states = states[:, :, end - 100:end]
    test_labels = labels[:, :, end - 100:end]


    train_loader = DataLoader((train_states, train_labels), batchsize = batch_size, shuffle = true)
    test_loader = DataLoader((test_states, test_labels), batchsize = batch_size)

    model = TetrisAI.Model.linear_QNet(258, 7)

    loss = logitcrossentropy

    ps = Flux.params(model) # model's trainable parameters

    opt = ADAM(lr)

    iter = ProgressBar(1:epochs)
    set_description(iter, "Pre-training the model on $epochs epochs, with $n_files states:")

    for _ in iter
        for (x, y) in train_loader
            gs = Flux.gradient(ps) do
                    ŷ = model(x)
                    loss(ŷ, y)
                end

            Flux.Optimise.update!(opt, ps, gs)
        end
    end

    # Testing the model
    acc = 0.0
	n = 0
	
	for (x, y) in test_loader
		ŷ = model(x)

		# Comparing the model's predictions with the labels
		acc += sum(onecold(ŷ |> cpu ) .== onecold(y |> cpu))

		# keeping track of the number of pictures we tested
		n += size(x)[end]
	end

    println("Final accuracy : ", acc/n * 100, "%")

    # Saving the finale model
    TetrisAI.Model.save_model(model_name, model)

end

function train_agent(agent::AbstractAgent; N::Int=100, limit_updates::Bool=true)

    update_rate::Int64 = 1
    if limit_updates
        update_rate = max(round(N * 0.05), 1)
    end

    agent.model = agent.model |> device

    # Creating the initial game
    game = TetrisGame()
    scores = Int[]

    iter = ProgressBar(1:N)
    set_description(iter, "Training the agent on $N games:")

    display(plot())

    for i in iter
        done = false
        score = 0

        while !done
            done, score = train!(agent, game)
        end

        push!(scores,score)

        if (i % update_rate) == 0
            display(plot(1:i, scores, title="Agent performance over $N games"))
        end
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
