using CUDA
using Flux: gpu, cpu
using Flux: onehotbatch, onecold
using Flux.Data: DataLoader
using Flux.Losses: logitcrossentropy
using Random

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
    policy_optimizer::Flux.Optimise.AbstractOptimiser = Flux.ADAM(policy_lr)
    val_optimizer::Flux.Optimise.AbstractOptimiser = Flux.ADAM(value_lr)

    ep_states::AbstractArray{<:Float32}       = []
    ep_acts::AbstractArray{<:Float32}         = []
    ep_gaes::AbstractArray{<:Float32}         = []
    ep_log_probs::AbstractArray{<:Float32}    = []
    ep_reward::Int                          = 0
end

function get_action(agent::PPOAgent, state::AbstractArray{<:Integer}, nb_outputs::Integer=7)
    final_move = zeros(Int, nb_outputs)
    logits = policy_forward(agent, state)
    act_dist = softmax(logits)
    act = sample(1:length(act_dist), Weights(act_dist))
    final_move[act] = 1
    return final_move
end

function reset_episode_data!(agent::PPOAgent)
    empty!(agent.ep_states)
    empty!(agent.ep_acts)
    empty!(agent.ep_gaes)
    empty!(agent.ep_log_probs)
    agent.ep_reward = 0
end

function perform_rollout_step(agent::PPOAgent, game::TetrisAI.Game.AbstractGame)
    train_data = []
    ep_reward = 0

    # TODO: Implement this correctly

    old_state = TetrisAI.Game.get_state(game)

    get_action(agent, )
    TetrisAI.send_input!(game, action)
    lines, done, score = TetrisAI.Game.tick!(game)    

    return done, score
end

function train!(agent::PPOAgent, game::TetrisAI.Game.AbstractGame)
    done, score = perform_rollout_step(agent, game)

    if done # In that case we need to train our agents

        # Shuffle the training data
        perms = randperm(length(agent.ep_states))

        agent.ep_states     = agent.ep_states[perms]
        agent.ep_acts       = agent.ep_acts[perms]
        agent.ep_log_probs  = agent.ep_acts[perms]
        agent.ep_reward     = discount_reward(agent.ep_reward, agent.γ)[perms]

        train_policy!(agent)
        train_value!(agent, returns)
        reset_episode_data!(agent)

        TetrisAI.Game.reset!(game)
        agent.n_games += 1

        if score > agent.record
            agent.record = score
        end
    end

    return done, score
end

function calculate_gaes(rewards::AbstractArray{<:Float32}, values::AbstractArray{<:Float32}, γ::Float32, decay::Float32)
    # TODO: Implement the GAES
end

function discount_reward(rewards::AbstractArray{<:Float32}, γ::Float32)
    new_rewards = [rewards[end]]
    for i in (length(rewards)-1):-1:1 # Reversed
        discounted = rewards[i] + γ * new_rewards[end]
        push!(new_rewards, discounted)
    return rewards
end

function to_device!(agent::PPOAgent)
end

function policy_forward(agent::PPOAgent, state::AbstractArray{<:Integer})
    shared_logits = agent.shared_layers(state)
    return agent.policy_model(shared_logits)
end

function value_forward(agent::PPOAgent, state::AbstractArray{<:Integer})
    shared_logits = agent.shared_layers(state)
    return agent.value_model(shared_logits)
end

function forward(agent::PPOAgent, state::AbstractArray{<:Integer})
    shared_logits = agent.shared_layers(state)
    policy_logits = agent.policy_model(shared_logits)
    value_logits = agent.value_model(shared_logits)
    return policy_logits, value_logits
end

function train_policy!(agent::PPOAgent)
    # TODO: IMPLEMENT
end

function train_value!(agent::PPOAgent, returns::AbstractArray{Float32})
    for _ in 1:agent.value_max_iters
        # TODO: Zero out the gradients

        values = value_forward(agent.ep_states, returns)
        value_loss = (returns - values)^2
        value_loss = mean(value_loss)

        # TODO: Compute gradients (value_loss.backward())
        # TODO: Gradient descent (agent.value_optimizer.step())
    end
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
    println("policy_optimizer => \t", agent.policy_optimizer)
    println("value_optimizer => \t", agent.val_optimizer)
end

function clone_behavior!(agent::PPOAgent)
end

