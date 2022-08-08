module Model

using BSON, NNlib, Flux

import ..TetrisAI: MODELS_PATH
import Flux: Chain, Dense, relu

export linear_QNet, random_Net, save_model, load_model

function save_model(name::AbstractString, model::Chain)

    file = string(name, ".bson")

    path = joinpath(MODELS_PATH, file)
    
    BSON.@save path model
    
    return
end

function load_model(name::AbstractString)

    file = string(name, ".bson")

    path = joinpath(MODELS_PATH, file)

    if isfile(path)
        model = get(BSON.load(path, @__MODULE__), :model, "Model_not_found")
    else
        print("Model not found.\n")
    end

    return model
end


include("models.jl")

end # module
