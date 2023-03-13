
Base.@kwdef mutable struct SarsaAgent <: MDPAgent 
    n_games::Int = 0
    record::Int = 0
    ϵ::Int = 0
    η::Float64 = 1e-3
    model = TetrisAI.Model.linear_QNet(258, 7)
    opt::Flux.Optimise.AbstractOptimiser = Flux.ADAM(η)
    loss::Function = Flux.Losses.logitcrossentropy
end


