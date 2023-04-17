using CUDA
using Flux: gpu, cpu
using Flux: onehotbatch, onecold
using Flux.Data: DataLoader
using Flux.Losses: logitcrossentropy
using StatsBase
using Random
using LinearAlgebra

if CUDA.functional()
    CUDA.allowscalar(false)
    device = gpu
else
    device = cpu
end

"""
    BufferKeys

Enum mapping keys for the experience replay buffer. Each key maps is used to map to a list.
"""
@enum BufferKeys begin
    KEY_REWARDS = 1     #"rewards"
    KEY_STATES = 2      #"states"
    KEY_ACTIONS = 3     #"actions"
    KEY_LOG_PROBS = 4   #"log_probs"
    KEY_GAES = 5        #"gaes"
    KEY_VALUES = 6      #"values"
    KEY_DONES = 7       #"dones"
end

"""
    PPOAgent

Agent that learns using the state-of-the-art reinforcement learning technique called [Proximal Policy Optimisation](https://arxiv.org/abs/1707.06347).
It's an on-policy learning algorithm and it's part of the Policy Gradient methods with an actor-critic architecture. It updates the policy within a
pessimistic trust region (clipped ratio of policies) so the agent avoids modifying the policy too drastically, hence increases learning stability.
"""
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
    max_ticks::Integer          = 20000
    ε::Float32                  = 0.02 # Clipping value
    γ::Float32                  = 0.99 # Reward discounting
    β::Float32                  = 0.01
    ζ::Float32                  = 1.0
    λ::Float32                  = 0.95 # GAE parameter
    ω::Float32                  = 0    # Reward shaping constant
    target_kl_div::Float32      = 0.01 
    policy_optimizer::Flux.Optimise.AbstractOptimiser = Flux.ADAM(policy_lr)
    val_optimizer::Flux.Optimise.AbstractOptimiser = Flux.ADAM(value_lr)
    reward_shaping::Bool        = false
end

function Base.show(io::IO, agent::PPOAgent)
    println("===========")
    println("AGENT ", agent.type)
    println("===========")
    println("n_games =>\t\t", agent.n_games)
    println("record =>\t\t", agent.record)
    println("shared_layers => \t", agent.shared_layers)
    println("policy_model => \t", agent.policy_model)
    println("value_model => \t\t", agent.value_model)
    println("policy_max_iters => \t", agent.policy_max_iters)
    println("value_max_iters => \t", agent.value_max_iters)
    println("policy_lr => \t\t", agent.policy_lr)
    println("value_lr => \t\t", agent.value_lr)
    println("target_kl_div => \t", agent.target_kl_div)
    println("ε => \t\t\t", agent.ε)
    println("γ => \t\t\t", agent.γ)
    println("β => \t\t\t", agent.β)
    println("ζ => \t\t\t", agent.ζ)
    println("λ => \t\t\t", agent.λ)
    println("policy_optimizer => \t", agent.policy_optimizer)
    println("value_optimizer => \t", agent.val_optimizer)
end

"""
    get_action(agent::PPOAgent, state::Vector, nb_outputs::Integer=7)

Selects an action from state using the distribution of action probabilities provided by the current policy.
"""
function get_action(agent::PPOAgent, state::Vector, nb_outputs::Integer=7)
    final_move = zeros(Int, nb_outputs)
    logits = policy_forward(agent, state)
    act_dist = softmax(logits)
    act = sample(1:length(act_dist), Weights(act_dist))
    final_move[act] = 1
    return final_move
end

"""
    rollout(agent::PPOAgent, game::TetrisAI.Game.AbstractGame)

Performs a complete episode while storing the episode data that will be used for optimizing the policy and the value models.
It returns the training data, the episode total rewards, the score and the number of ticks from the episode.
"""
function rollout(agent::PPOAgent, game::TetrisAI.Game.AbstractGame)
    ep_reward = 0
    nb_ticks = 0
    score = 0
    done = false
    old_state = TetrisAI.Game.get_state(game)
    train_data::Dict{BufferKeys, Vector{Any}} = Dict([
        (KEY_STATES, []),
        (KEY_ACTIONS, []),
        (KEY_LOG_PROBS, []),
        (KEY_REWARDS, []),
        (KEY_GAES, []),
        (KEY_VALUES, []),
        (KEY_DONES, [])
    ])

    while !done || nb_ticks > agent.max_ticks
        
        reward = 0

        # Get the predicted move for the state
        policy_logits, val = forward(agent, old_state)
        act_dist = softmax(policy_logits)
        act_log_probs = log.(act_dist)
        act = sample(1:length(act_dist), Weights(act_dist))
        action_vect = zeros(Int, length(act_dist))
        action_vect[act] = 1

        #-! Play the action
        TetrisAI.send_input!(game, action_vect)          # Send the action
        lines, done, score = TetrisAI.Game.tick!(game)  # Play the step
        new_state = TetrisAI.Game.get_state(game)

        #-! Compute reward according to the number of lines cleared
        if agent.reward_shaping
            reward = shape_rewards(game, lines, score, agent.ω)
        else
            if lines > 0
                reward = [1, 5, 10, 50][lines]
            end
        end

        #-! Append the old stuff to the training data
        push!(train_data[KEY_STATES], old_state)
        push!(train_data[KEY_ACTIONS], action_vect)
        push!(train_data[KEY_REWARDS], reward)
        push!(train_data[KEY_VALUES], val)
        push!(train_data[KEY_LOG_PROBS], act_log_probs)
        push!(train_data[KEY_DONES], done)

        old_state = new_state
        ep_reward += reward
        nb_ticks = nb_ticks + 1
    end

    train_data[KEY_GAES] = calculate_gaes(train_data[KEY_REWARDS], train_data[KEY_VALUES], train_data[KEY_DONES], agent.γ, agent.λ)

    return train_data, ep_reward, score, nb_ticks
end

"""
    train!(agent::PPOAgent, game::TetrisAI.Game.TetrisGame, N::Int=100, limit_updates::Bool=true)

Trains the agent using trust region policy updates (clip) from PPO.
"""
function train!(agent::PPOAgent, game::TetrisAI.Game.TetrisGame, N::Int=100, limit_updates::Bool=true, render::Bool=true, run_id::String="")
    benchmark = ScoreBenchMark(n=N)

    update_rate::Int64 = 1
    if limit_updates
        update_rate = max(round(N * 0.05), 1)
    end

    to_device!(agent)

    iter = ProgressBar(1:N)
    set_description(iter, "Training the agent on $N games:")

    for _ in iter
        
        train_data, reward, score, nb_ticks = rollout(agent, game)

        # Shuffle the training data
        perms = randperm(length(get(train_data, KEY_STATES, [])))

        # TODO: to device each list
        states      = get(train_data, KEY_STATES, [])[perms]
        acts        = get(train_data, KEY_ACTIONS, [])[perms]
        log_probs   = get(train_data, KEY_LOG_PROBS, [])[perms]
        gaes        = get(train_data, KEY_GAES, [])[perms]
        returns     = discount_reward(get(train_data, KEY_REWARDS, []), agent.γ)[perms]

        train_policy!(agent, states, acts, log_probs, gaes, returns)
        train_value!(agent, states, returns)

        TetrisAI.Game.reset!(game)
        agent.n_games += 1
        agent.record = max(score, agent.record)

        append_score_ticks!(benchmark, score, nb_ticks, reward)
        update_benchmark(benchmark, update_rate, iter, render)
    end

    save_to_csv(benchmark, agent.type, run_id)

    @info "Agent high score after $N games => $(agent.record) pts"
end

"""
    calculate_gaes(rewards::Vector, values::Vector, γ::Float32, decay::Float32)

Returns the General Advantage Estimates from the given rewards and values. (See [article of reference](https://arxiv.org/pdf/1506.02438.pdf).)
"""
function calculate_gaes(rewards::Vector, values::Vector, dones::Vector, γ::Float32, λ::Float32)
    # TODO: Implement the GAES
    next_values = values[2:end]
    push!(next_values, 0)
    gaes = []
    deltas = []

    for i in eachindex(rewards)
        δ = rewards[i] .+ γ * (1 - dones[i]) * next_values[i] .- values[i]
        push!(deltas, δ)
    end

    gaes = deepcopy(deltas)
    for t in (length(deltas)-1):-1:1
        gaes[t] = gaes[t] + (1 - dones[t]) * γ * λ * gaes[t+1]
    end

    gaes = vec(Flux.stack(gaes))

    return gaes
end

"""
    discount_reward(rewards::Vector{<:Float32}, γ::Float32)

Returns the discounted rewards based on the timestep each reward was received given a gamma hyperparameter.
"""
function discount_reward(rewards::Vector, γ::Float32)
    new_rewards = [rewards[end]]
    for i in (length(rewards)-1):-1:1 # Reversed
        discounted = rewards[i] + γ * new_rewards[end]
        push!(new_rewards, discounted)
    end
    return new_rewards
end

"""
    policy_forward(agent::PPOAgent, state::Union{Vector, Matrix})

Compute and returns the logits from the policy network obtained from the current state and the shared layers output.
"""
function policy_forward(agent::PPOAgent, state::Union{Vector, Matrix})
    shared_logits = agent.shared_layers(state)
    return agent.policy_model(shared_logits)
end

"""
    value_forward(agent::PPOAgent, state::Union{Vector, Matrix})

Compute and returns the logits from the value network obtained from the current state and the shared layers output.
"""
function value_forward(agent::PPOAgent, state::Union{Vector, Matrix})
    shared_logits = agent.shared_layers(state)
    return agent.value_model(shared_logits)
end

"""
    forward(agent::PPOAgent, state::Union{Vector, Matrix})

Compute and returns the logits from the policy and the value networks obtained from the current state and the shared layers output.
"""
function forward(agent::PPOAgent, state::Union{Vector, Matrix})
    shared_logits = agent.shared_layers(state)
    policy_logits = agent.policy_model(shared_logits)
    value_logits = agent.value_model(shared_logits)
    return policy_logits, value_logits
end

"""
    train_policy!(agent::PPOAgent, states::Vector, acts::Vector, old_log_probs::Vector, gaes::Vector, returns::Vector)

Updates the agent's policy using agent.policy_max_iters iterations to modify the policy by optimizing PPO's surrogate objective
function.
"""
function train_policy!(agent::PPOAgent, states::Vector, acts::Vector, old_log_probs::Vector, gaes::Vector, returns::Vector)
    value_loss(a, s, ret) = mean((ret .- value_forward(a, s))^2)
    clip(val) = clamp(val, 1-agent.ε, 1+agent.ε)
    policy_ratio = 0
    acts_one_cold = Flux.onecold.(acts)
    old_log_probs_batched = Flux.batch(old_log_probs) |> x -> convert.(Float32, x) |> device
    states = Flux.batch(states) |> x -> convert.(Float32, x) |> device
    for _ in 1:agent.policy_max_iters
        ps = Flux.params(agent.shared_layers, agent.policy_model)
        new_policy_logits = policy_forward(agent, states)
        new_probs = softmax(new_policy_logits)
        new_log_probs = log.(new_probs)

        entropy = agent.β * dot(new_probs, new_log_probs)

        old_log_probs_batched = [old_log_probs_batched[x, y] for (x, y) in zip(acts_one_cold,collect(1:length(acts_one_cold)))]
        new_log_probs = [new_log_probs[x, y] for (x, y) in zip(acts_one_cold,collect(1:length(acts_one_cold)))]

        policy_ratio = exp.(new_log_probs .- old_log_probs_batched)
        full_loss = policy_ratio .* gaes
        clipped_loss = clip.(policy_ratio) .* gaes
        loss = min(mean(full_loss), mean(clipped_loss)) + agent.ζ * value_loss(agent, states, returns) + entropy
        gs = Flux.gradient(ps) do 
            loss
        end

        Flux.Optimise.update!(agent.policy_optimizer, ps, gs)

        # TODO: Verify that the estimate of the kl_div works
        kl_div = mean(policy_ratio)
        if kl_div >= agent.target_kl_div
            break
        end
    end
end

"""
    train_value!(agent::PPOAgent, returns::Vector{Float32})

Updates the agent's value function using a mean squared difference loss on the value estimations and the actual returns
for agent.value_max_iters iterations.
"""
function train_value!(agent::PPOAgent, states::Vector, returns::Vector)
    states_batched = Flux.batch(states) |> x -> convert.(Float32, x) |> device
    returns_batched = Flux.batch(returns) |> x -> convert.(Float32, x) |> device

    for _ in 1:agent.value_max_iters

        ps = Flux.params(agent.shared_layers, agent.value_model)
        squared_loss = mean((returns_batched .- value_forward(agent, states_batched))^2)
        gs = Flux.gradient(ps) do
            squared_loss
        end
        
        Flux.Optimise.update!(agent.val_optimizer, ps, gs)
    end
end

"""
    clone_behavior!(agent::PPOAgent)

[NOT IMPLEMENTED] Will pre-train the PPO agent based on an expert dataset.
"""
function clone_behavior!(agent::PPOAgent)
end

"""
    to_device!(agent::PPOAgent)

Send the agent's models (shared, policy & value) to cpu/cuda device.
"""
function to_device!(agent::PPOAgent)
    agent.shared_layers = agent.shared_layers |> device
    agent.policy_model = agent.policy_model |> device
    agent.value_model = agent.value_model |> device
end

