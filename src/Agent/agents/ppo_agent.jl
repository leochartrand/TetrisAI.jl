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

"""
    BufferKeys

Enum mapping keys for the experience replay buffer. Each key maps is used to map to a list.
"""
@enum BufferKeys begin
    KEY_REWARDS = "rewards"
    KEY_STATES = "states"
    KEY_ACTIONS = "actions"
    KEY_LOG_PROBS = "log_probs"
    KEY_GAES = "gaes"
    KEY_VALUES = "values"
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
    gaes_decay::Float32         = 0.97

    # might miss the value params here
    # might miss the policy params here

    ε::Float32                  = 0.02 # Clipping value
    γ::Float32                  = 0.99 # Reward discounting
    target_kl_div::Float32      = 0.01 
    policy_optimizer::Flux.Optimise.AbstractOptimiser = Flux.ADAM(policy_lr)
    val_optimizer::Flux.Optimise.AbstractOptimiser = Flux.ADAM(value_lr)
    reward_shaping::Bool        = false
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
    println("target_kl_div => \t", agent.target_kl_div)
    println("ε => \t\t", agent.ε)
    println("γ => \t\t", agent.γ)
    println("policy_optimizer => \t", agent.policy_optimizer)
    println("value_optimizer => \t", agent.val_optimizer)
    println("gaes_decay => \t", agent.gaes_decay)
end

"""
    get_action(agent::PPOAgent, state::AbstractArray{<:Integer}, nb_outputs::Integer=7)

Selects an action from state using the distribution of action probabilities provided by the current policy.
"""
function get_action(agent::PPOAgent, state::AbstractArray{<:Integer}, nb_outputs::Integer=7)
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
    train_data::AbstractArray = Dict([
        (KEY_STATES, []),
        (KEY_ACTIONS, []),
        (KEY_LOG_PROBS, []),
        (KEY_REWARDS, []),
        (KEY_GAES, []),
        (KEY_VALUES, [])
    ])

    while !done || nb_ticks > agent.max_ticks
        
        reward = 0

        # Get the predicted move for the state
        policy_logits, val = forward(agent, state)
        act_dist = softmax(policy_logits)
        act_log_probs = log(act_dist)
        act = sample(1:length(act_dist), Weights(act_dist))
        action_vect = zeros(Int, length(act_dist))
        action_vect[act] = 1

        #-! Play the action
        TetrisAI.send_input!(game, final_move)          # Send the action
        lines, done, score = TetrisAI.Game.tick!(game)  # Play the step
        new_state = TetrisAI.Game.get_state(game)

        #-! Compute reward according to the number of lines cleared
        if agent.reward_shaping
            reward = shape_rewards(game, lines)
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

        old_state = new_state
        ep_reward += reward
        nb_ticks = nb_ticks + 1
    end

    train_data[KEY_GAES] = calculate_gaes(train_data[KEY_REWARDS], train_data[KEY_VALUES], agent.γ, agent.gaes_decay)

    return train_data, ep_reward, score, nb_ticks
end

"""
    train!(agent::PPOAgent, game::TetrisAI.Game.TetrisGame, N::Int=100, limit_updates::Bool=true)

Trains the agent using trust region policy updates (clip) from PPO.
"""
function train!(agent::PPOAgent, game::TetrisAI.Game.TetrisGame, N::Int=100, limit_updates::Bool=true)
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
        perms = randperm(length(ep_states))

        # TODO: to device each list
        states      = get(train_data, KEY_STATES, [])[perms]
        acts        = get(train_data, KEY_ACTIONS, [])[perms]
        log_probs   = get(train_data, KEY_LOG_PROBS, [])[perms]
        gaes        = get(train_data, KEY_GAES, [])[perms]
        returns     = discount_reward(get(train_data, KEY_REWARDS, []), agent.γ)[perms]

        train_policy!(agent, states, acts, log_probs, gaes)
        train_value!(agent, states, returns)

        TetrisAI.Game.reset!(game)
        agent.n_games += 1
        agent.record = max(score, agent.record)

        append_score_ticks!(benchmark, score, nb_ticks, reward)
        update_benchmark(benchmark, update_rate, iter, render)
    end

    save_to_csv(benchmark, run_id)

    @info "Agent high score after $N games => $(agent.record) pts"
end

"""
    calculate_gaes(rewards::AbstractArray{<:Float32}, values::AbstractArray{<:Float32}, γ::Float32, decay::Float32)

Returns the General Advantage Estimates from the given rewards and values. (See [article of reference](https://arxiv.org/pdf/1506.02438.pdf).)
"""
function calculate_gaes(rewards::AbstractArray{<:Float32}, values::AbstractArray{<:Float32}, γ::Float32, decay::Float32)
    # TODO: Implement the GAES
end

"""
    discount_reward(rewards::AbstractArray{<:Float32}, γ::Float32)

Returns the discounted rewards based on the timestep each reward was received given a gamma hyperparameter.
"""
function discount_reward(rewards::AbstractArray{<:Float32}, γ::Float32)
    new_rewards = [rewards[end]]
    for i in (length(rewards)-1):-1:1 # Reversed
        discounted = rewards[i] + γ * new_rewards[end]
        push!(new_rewards, discounted)
    return rewards
end

"""
    policy_forward(agent::PPOAgent, state::AbstractArray{<:Integer})

Compute and returns the logits from the policy network obtained from the current state and the shared layers output.
"""
function policy_forward(agent::PPOAgent, state::AbstractArray{<:Integer})
    shared_logits = agent.shared_layers(state)
    return agent.policy_model(shared_logits)
end

"""
    value_forward(agent::PPOAgent, state::AbstractArray{<:Integer})

Compute and returns the logits from the value network obtained from the current state and the shared layers output.
"""
function value_forward(agent::PPOAgent, state::AbstractArray{<:Integer})
    shared_logits = agent.shared_layers(state)
    return agent.value_model(shared_logits)
end

"""
    forward(agent::PPOAgent, state::AbstractArray{<:Integer})

Compute and returns the logits from the policy and the value networks obtained from the current state and the shared layers output.
"""
function forward(agent::PPOAgent, state::AbstractArray{<:Integer})
    shared_logits = agent.shared_layers(state)
    policy_logits = agent.policy_model(shared_logits)
    value_logits = agent.value_model(shared_logits)
    return policy_logits, value_logits
end

"""
    train_policy!(agent::PPOAgent, obs::AbstractArray, acts::AbstractArray, old_log_probs::AbstractArray, gaes::AbstractArray)

Updates the agent's policy using agent.policy_max_iters iterations to modify the policy by optimizing PPO's surrogate objective
function.
"""
function train_policy!(agent::PPOAgent, states::AbstractArray, acts::AbstractArray, old_log_probs::AbstractArray, gaes::AbstractArray)
    
    policy_ratio = 0
    for _ in 1:agent.policy_max_iters
        ps = Flux.params(agent.policy_model)
        gs = Flux.gradient(ps) do 
            new_logits = agent.policy_model(states)
            new_log_probs = log(softmax(new_logits))
            policy_ratio = new_log_probs - old_log_probs
            full_loss = policy_ratio * gaes
            clipped_loss = clamp(policy_ratio, 1-agent.ε, 1+agent.ε) * gaes
            min(full_loss, clipped_loss)
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
    train_value!(agent::PPOAgent, returns::AbstractArray{Float32})

Updates the agent's value function using a mean squared difference loss on the value estimations and the actual returns
for agent.value_max_iters iterations.
"""
function train_value!(agent::PPOAgent, states::AbstractArray{Float32}, returns::AbstractArray{Float32})
    loss(a, s, ret) = mean((ret - value_forward(a, s))^2)
    for _ in 1:agent.value_max_iters

        ps = Flux.params(agent.value_model)
        gs = Flux.gradient(ps) do
            loss(agent, states, returns)
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

function to_device!(agent::PPOAgent)
end

