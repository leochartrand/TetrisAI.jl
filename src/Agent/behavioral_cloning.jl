using CUDA
using Flux: gpu, cpu
using Flux: onehotbatch, onecold
using Flux.Data: DataLoader
using Flux.Losses: logitcrossentropy

# Should be refactored
const DATA_PATH = joinpath(TetrisAI.PROJECT_ROOT, "data")
const STATES_PATH = joinpath(DATA_PATH, "states")
const LABELS_PATH = joinpath(DATA_PATH, "labels")

"""
Clones behavior from expert data to policy neural net
"""
function clone_behavior!(
    model, 
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)

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

    ps = Flux.params(model) # model's trainable parameters

    loss = Flux.Losses.logitcrossentropy

    opt = Flux.ADAM(lr)

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

    return model
end