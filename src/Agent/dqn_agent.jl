
Base.@kwdef mutable struct DQNAgent <: MDPAgent
    n_games::Int = 0
    record::Int = 0
    η::Float64 = 1e-3
    γ::Float64 = (1 - 1e-2)
    ϵ::Int = 1
    ϵ_decay::Int = 1
    ϵ_min::Int = 0.05
    memory::AgentMemory = CircularBufferMemory()
    main_net = TetrisAI.Model.linear_QNet(258, 7)
    target_net = TetrisAI.Model.linear_QNet(258, 7)
    opt::Flux.Optimise.AbstractOptimiser = Flux.ADAM(η)
    loss::Function = Flux.Losses.logitcrossentropy
end

