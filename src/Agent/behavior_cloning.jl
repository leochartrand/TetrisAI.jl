using CUDA
using Flux: gpu, cpu
using Flux: onehotbatch, onecold
using Flux.Data: DataLoader
using Flux.Losses: logitcrossentropy
using JSON, ProgressBars, Plots

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
    clone_behavior!(
        agent::AbstractAgent,
        model,
        lr::Float64 = 5e-4, 
        batch_size::Int64 = 50, 
        epochs::Int64 = 80)

Clones behavior from expert data to policy neural net
"""
function clone_behavior!(
    agent::AbstractAgent,
    model,
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)

    if agent.feature_extraction
        states = Array{Real,2}(undef,agent.n_features,0)
    else
        states = Array{Real,2}(undef,228,0)
    end
    labels = Array{Real,2}(undef,1,0)

    n_states = 0

    # Ignore hidden files
    states_files = [joinpath(STATES_PATH, file) for file in readdir(STATES_PATH) if startswith(file, ".") == false]
    labels_files = [joinpath(LABELS_PATH, file) for file in readdir(LABELS_PATH) if startswith(file, ".") == false]

    for file in states_files
        states_data = JSON.parse(readline(file), dicttype=Dict{String,Vector{Int64}})
        for state in states_data
            state = (state |> values |> collect)[1]
            if agent.feature_extraction
                state = state |> get_state_features
            end
            n_states += 1
            states = hcat(states, state)
        end
    end

    for file in labels_files
        labels_data = JSON.parse(readline(file), dicttype=Dict{String,Int64})
        for label in labels_data
            label = label |> values |> collect
            labels = hcat(labels, label)
        end
    end

    # Convert labels to onehot vectors
    labels = dropdims(Flux.onehotbatch(labels,1:7);dims=2)

    # Homemade split to have at least a testing metric
    train_states = states[:, begin:end - 101] |> device
    train_labels = labels[:, begin:end - 101] |> device
    test_states = states[:, end - 100:end] |> device
    test_labels = labels[:, end - 100:end] |> device

    train_loader = DataLoader((train_states, train_labels), batchsize = batch_size, shuffle = true)
    test_loader = DataLoader((test_states, test_labels), batchsize = batch_size)

    to_device!(agent)

    ps = Flux.params(model) # model's trainable parameters

    loss = Flux.Losses.logitcrossentropy

    opt = Flux.ADAM(lr)

    iter = ProgressBar(1:epochs)
    println("Pre-training the model on $epochs epochs, with $n_states states.")
    set_description(iter, "Epoch: 0/$epochs:")
    for it in iter
        set_description(iter, "Epoch: $it/$epochs:")
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

    return model
end