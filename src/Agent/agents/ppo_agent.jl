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

    # might miss the value params here
    # might miss the policy params here

    ε::Float32                  = 0.02 # Clipping value
    γ::Float32                  = 0.99 # Reward discounting
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
    println("ε => \t\t", agent.ε)
    println("γ => \t\t", agent.γ)
    println("policy_optimizer => \t", agent.policy_optimizer)
    println("value_optimizer => \t", agent.val_optimizer)
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
    train_data::AbstractArray = Dict([
        (KEY_STATES, []),
        (KEY_ACTIONS, []),
        (KEY_LOG_PROBS, []),
        (KEY_REWARDS, []),
        (KEY_GAES, [])
    ])

    while !done || nb_ticks > agent.max_ticks
        # Get the current step
        old_state = TetrisAI.Game.get_state(game)

        # Get the predicted move for the state
        action = get_action(agent, old_state)
        TetrisAI.send_input!(game, action)

        reward = 0
        # Play the step
        lines, done, score = TetrisAI.Game.tick!(game)
        new_state = TetrisAI.Game.get_state(game)

        # Adjust reward accoring to amount of lines cleared
        if agent.reward_shaping
            reward = shape_rewards(game, lines)
        else
            if lines > 0
                reward = [1, 5, 10, 50][lines]
            end
        end

        nb_ticks = nb_ticks + 1
    end

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
        train_value!(agent, returns)

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

function to_device!(agent::PPOAgent)
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
function train_policy!(agent::PPOAgent, obs::AbstractArray, acts::AbstractArray, old_log_probs::AbstractArray, gaes::AbstractArray)
    # TODO: IMPLEMENT
end

"""
    train_value!(agent::PPOAgent, returns::AbstractArray{Float32})

Updates the agent's value function using a mean squared difference loss on the value estimations and the actual returns
for agent.value_max_iters iterations.
"""
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

"""
    clone_behavior!(agent::PPOAgent)

[NOT IMPLEMENTED] Will pre-train the PPO agent based on an expert dataset.
"""
function clone_behavior!(agent::PPOAgent)
end

