module Model

using BSON, NNlib, Flux, Dates

import ..TetrisAI: MODELS_PATH
import Flux: Chain, Dense, relu

export dense_net, random_Net, save_model, load_model

function save_model(model::Chain, name::AbstractString=nothing)

    if isnothing(name)
        suffix = Dates.format(DateTime(now()), "yyyymmddHHMMSS")
        name = "model_$suffix"
    end

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
