using CUDA
using Flux: gpu, cpu
using Flux: onehotbatch, onecold
using Flux.Data: DataLoader
using Flux.Losses: logitcrossentropy

if CUDA.functional()
    CUDA.allowscalar(false)
    device = gpu
else
    device = cpu
end

Base.@kwdef mutable struct PPOAgent <: AbstractAgent
    type::String                = "PPO"
    n_games::Int                = 0    # Number of games played
    record::Int                 = 0    # Best score so far
    shared_layers               = TetrisAI.Model.ppo_shared_layers(228)
    policy_model                = TetrisAI.Model.policy_ppo_net(512, 7)
    value_model                 = TetrisAI.Model.value_ppo_net(512)
    policy_max_iters::Integer   = 100
    value_max_iters::Integer    = 100
    policy_lr::Float32          = 1e-4
    value_lr::Float32           = 1e-2

    # might miss the value params here
    # might miss the policy params here

    ε::Float32                  = 0.02 # Clipping value
    γ::Float32                  = 0.99 # Reward discounting
end

function get_action(agent::PPOAgent, nb_outputs::Integer=7)
end

function train!(agent::PPOAgent, game::TetrisAI.Game.AbstractGame)
end

function to_device!(agent::PPOAgent)
end


function Base.show(io::IO, agent::PPOAgent)
    println("AGENT ", agent.type)
    println("n_games =>\t\t", agent.n_games)
    println("record =>\t\t", agent.record)
    println("shared_layers => \t", agent.shared_layers)
    println("policy_layers => \t", agent.policy_layers)
    println("value_layers => \t", agent.value_layers)
    println("policy_max_iters => \t", agent.policy_max_iters)
    println("value_max_iters => \t", agent.value_max_iters)
    println("policy_lr => \t", agent.policy_lr)
    println("value_lr => \t", agent.value_lr)
    println("ε => \t\t", agent.ε)
    println("γ => \t\t", agent.γ)
end

function clone_behavior!(agent::PPOAgent)
end

