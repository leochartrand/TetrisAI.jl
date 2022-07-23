module Model

import ..TetrisAI: MODELS_PATH

import BSON: @save
import Flux: Chain, Dense, relu

export linear_QNet, random_Net, save_model

function save_model(name::AbstractString, model::Chain)
    @save joinpath(MODELS_PATH, name) model
    return
end

include("models.jl")

end # module
