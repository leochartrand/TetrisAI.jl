using CUDA
using Flux: gpu, cpu
using Flux: onehotbatch, onecold
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
    PPOAgent

Agent that learns using the state-of-the-art reinforcement learning technique called [Proximal Policy Optimisation](https://arxiv.org/abs/1707.06347).
It's an on-policy learning algorithm and it's part of the Policy Gradient methods with an actor-critic architecture. It updates the policy within a
pessimistic trust region (clipped ratio of policies) so the agent avoids modifying the policy too drastically, hence increases learning stability.
"""
Base.@kwdef mutable struct PPOAgent <: AbstractAgent
    type::String                = "PPO"
    n_games::Int                = 0    # Number of games played
    record::Int                 = 0    # Best score so far
    feature_extraction::Bool    = true
    n_features::Int             = 17
    reward_shaping::Bool        = true 
    shared_layers               = (feature_extraction ? TetrisAI.Model.ppo_shared_layers_dense(n_features) : TetrisAI.Model.ppo_shared_layers_dense(n_features)) |> device
    policy_model                = TetrisAI.Model.policy_ppo_net(512, 7) |> device
    value_model                 = TetrisAI.Model.value_ppo_net(512) |> device
    policy_max_iters::Integer   = 100
    value_max_iters::Integer    = 100
    policy_lr::Float64          = 1e-4
    value_lr::Float64           = 1e-2
    max_ticks::Integer          = 20000
    ε::Float64                  = 0.02 # Clipping value
    γ::Float64                  = 0.99 # Reward discounting
    β::Float64                  = 0.01
    ζ::Float64                  = 1.0
    λ::Float64                  = 0.95 # GAE parameter
    ω::Float64                  = 0    # Reward shaping constant
    reward_shaping_score::Float64  = 0
    horizon::Int                = 5  # T timesteps
    target_kl_div::Float64      = 0.01 
    memory::CircularBuffer      = TrajectoryBuffer(PPO_Transition, horizon).data
    policy_optimizer::Flux.Optimise.AbstractOptimiser = Flux.ADAM(policy_lr)
    val_optimizer::Flux.Optimise.AbstractOptimiser = Flux.ADAM(value_lr)
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
    println("ω => \t\t\t", agent.ω)
    println("reward_shaping_score => \t", agent.reward_shaping_score)
    println("reward_shaping => \t", agent.reward_shaping)
    println("horizon => \t\t", agent.horizon)
    println("policy_optimizer => \t", agent.policy_optimizer)
    println("value_optimizer => \t", agent.val_optimizer)
end

"""
    get_action(agent::PPOAgent, state::Vector, nb_outputs::Integer=7)

Select an action from state using the distribution of action probabilities provided by the current policy.
"""
function get_action(agent::PPOAgent, state::AbstractArray{<:Real}, nb_outputs::Integer=7)
    state = process_state(agent, state) |> device
    final_move = zeros(Int, nb_outputs)
    logits = policy_forward(agent, state)
    logits = logits |> cpu
    act_dist = softmax(logits)
    act = sample(1:length(act_dist), Weights(act_dist))
    final_move[act] = 1
    return final_move
end

"""
    train!(agent::PPOAgent, game::TetrisAI.Game.TetrisGame, N::Int=100, limit_updates::Bool=true)

Train the agent using trust region policy updates (clip) from PPO.
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
        
        reward, score, nb_ticks = rollout(agent, game)

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
    rollout(agent::PPOAgent, game::TetrisAI.Game.AbstractGame)

Perform a complete episode while storing the episode data that will be used for optimizing the policy and the value models.
It returns the training data, the episode total rewards, the score and the number of ticks from the episode.
"""
function rollout(agent::PPOAgent, game::TetrisAI.Game.AbstractGame)
    ep_reward = 0.
    nb_ticks = 0
    num_steps = 0
    score = 0
    done = false
    old_state = process_state(agent, TetrisAI.Game.get_state(game))

    while !done && nb_ticks < agent.max_ticks
        
        reward = 0.
        
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
        new_state = process_state(agent, TetrisAI.Game.get_state(game))

        #-! Compute reward according to the number of lines cleared
        if done
            reward = -10
        elseif agent.reward_shaping
            reward, agent.ω, agent.reward_shaping_score = shape_rewards(game, lines, agent.reward_shaping_score, agent.ω)
        else
            if lines > 0
                reward = [1, 5, 10, 50][lines] |> f64
            end
        end

        #-! Append the old stuff to the training data
        transition = PPO_Transition(old_state, action_vect, reward, act_log_probs, val, done)
        push!(agent.memory, transition)

        old_state  = new_state
        ep_reward += reward
        nb_ticks  += 1
        num_steps += 1

        if num_steps >= agent.horizon || done || nb_ticks >= agent.max_ticks
            update!(agent)
            num_steps = 0
        end
    end

    return ep_reward, score, nb_ticks
end

"""
    update!(agent::PPOAgent)
"""
function update!(agent::PPOAgent)
    # Shuffle the training data
    perms = randperm(length(agent.memory))

    states, actions, rewards, log_probs, values, dones = map(x -> getfield.(agent.memory, x), fieldnames(eltype(agent.memory)))

    states      = states[perms] |> device
    actions     = actions[perms] |> device
    log_probs   = log_probs[perms] |> device
    gaes        = calculate_gaes(rewards, values, dones, agent.γ, agent.λ)[perms] |> device
    returns     = discount_reward(rewards, agent.γ)[perms] |> device

    update_policy!(agent, states, actions, log_probs, gaes, returns)
    update_value!(agent, states, returns)
    empty!(agent.memory)
end

"""
    calculate_gaes(rewards::Vector{Float64}, values::Vector{Float64}, γ::Float64, decay::Float64)

Compute the General Advantage Estimates from the given rewards and values. (See [article of reference](https://arxiv.org/pdf/1506.02438.pdf).)
"""
function calculate_gaes(rewards::Vector{Float64}, values::Vector{Float64}, dones::Union{Vector{Bool},BitVector}, γ::Float64, λ::Float64)
    # TODO: Implement the GAES
    next_values = values[2:end]
    push!(next_values, 0.)
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
    discount_reward(rewards::Vector{<:Float64}, γ::Float64)

Compute the discounted rewards based on the timestep each reward was received given a gamma hyperparameter.
"""
function discount_reward(rewards::Vector{Float64}, γ::Float64)
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
function policy_forward(agent::PPOAgent, state::Union{Matrix{Float64},Vector{Float64}})
    shared_logits = agent.shared_layers(state)
    return agent.policy_model(shared_logits)
end

"""
    value_forward(agent::PPOAgent, state::Union{Vector, Matrix})

Compute and returns the logits from the value network obtained from the current state and the shared layers output.
"""
function value_forward(agent::PPOAgent, state::Union{Matrix{Float64},Vector{Float64}})
    shared_logits = agent.shared_layers(state)
    return agent.value_model(shared_logits)[1]
end

"""
    forward(agent::PPOAgent, state::Union{Vector, Matrix})

Compute and returns the logits from the policy and the value networks obtained from the current state and the shared layers output.
"""
function forward(agent::PPOAgent, state::Union{Matrix{Float64},Vector{Float64}})
    shared_logits = agent.shared_layers(state)
    policy_logits = agent.policy_model(shared_logits)
    value_logits = agent.value_model(shared_logits)[1]
    return policy_logits, value_logits
end

"""
    update_policy!(
        agent::PPOAgent, 
        states::Vector, 
        acts::Vector, 
        old_log_probs::Vector, 
        gaes::Vector, 
        returns::Vector)

Update the agent's policy using agent.policy_max_iters iterations to modify the policy by optimizing PPO's surrogate objective
function.
"""
function update_policy!(
    agent::PPOAgent, 
    states::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}}, 
    actions::Vector{Array{Int64,1}}, 
    old_log_probs::Vector{Array{Float64,1}}, 
    gaes::Vector{Float64}, 
    returns::Vector{Float64})

    value_loss(a, s, ret) = mean((ret .- value_forward(a, s)).^2)
    clip(val) = clamp(val, 1-agent.ε, 1+agent.ε)
    policy_ratio = 0
    acts_one_cold = Flux.onecold.(actions)
    old_log_probs_batched = Flux.batch(old_log_probs) |> x -> convert.(Float64, x) |> device
    states = Flux.batch(states) |> x -> convert.(Float64, x) |> device
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
    update_value!(
        agent::PPOAgent, 
        states::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}}, 
        returns::Vector{Float64})

Update the agent's value function using a mean squared difference loss on the value estimations and the actual returns
for agent.value_max_iters iterations.
"""
function update_value!(
    agent::PPOAgent, 
    states::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}}, 
    returns::Vector{Float64})

    states_batched = Flux.batch(states) |> x -> convert.(Float64, x) |> device
    returns_batched = Flux.batch(returns) |> x -> convert.(Float64, x) |> device

    for _ in 1:agent.value_max_iters

        ps = Flux.params(agent.shared_layers, agent.value_model)
        squared_loss = mean((returns_batched .- value_forward(agent, states_batched)).^2)
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

function sleep(agent::PPOAgent) 
    agent.memory = CircularBuffer{Int}(0)
end

function awake(agent::PPOAgent) 
    agent.memory = TrajectoryBuffer(PPO_Transition, agent.horizon).data
end

