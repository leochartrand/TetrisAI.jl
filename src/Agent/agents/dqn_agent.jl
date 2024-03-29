using CUDA
using Flux: gpu, cpu
using Flux: onehotbatch, onecold
using Flux.Losses: logitcrossentropy
using Dates

if CUDA.functional()
    CUDA.allowscalar(false)
    device = gpu
else
    device = cpu
end

"""
    DQNAgent

Off-Policy Deep-Q-learning agent, with ϵ-greedy policy, target net and experience replay.
"""
Base.@kwdef mutable struct DQNAgent <: AbstractAgent
    type::String = "DQN"
    n_games::Int = 0
    record::Int = 0
    feature_extraction::Bool = true
    n_features::Int = 17
    reward_shaping::Bool = true
    reward_shaping_score::Float64 = 0.
    ω::Float64 = 0              # Reward shaping constant
    η::Float64 = 1e-3           # Learning rate
    γ::Float64 = (1 - 1e-2)     # Discount factor
    τ::Float64 = 5e-3           # Soft update rate
    ϵ::Float64 = 1              # Exploration
    ϵ_decay::Float64 = 1
    ϵ_min::Float64 = 0.05
    batch_size::Int = 128
    memory::CircularBuffer = ReplayBuffer(DQN_Transition).data
    policy_net = (feature_extraction ? TetrisAI.Model.dense_net(n_features) : TetrisAI.Model.conv_net()) |> device
    target_net = (feature_extraction ? TetrisAI.Model.dense_net(n_features) : TetrisAI.Model.conv_net()) |> device
    opt::Flux.Optimise.AbstractOptimiser = Flux.ADAM(η)
    loss::Function = logitcrossentropy
end

"""
    Base.show(io::IO, agent::DQNAgent)
"""
function Base.show(io::IO, agent::DQNAgent)
    println("n_games => ", agent.n_games)
    println("record => ", agent.record)
    println("feature extraction => ", agent.feature_extraction)
    println("reward shaping => ", agent.reward_shaping)
    println("Reward shaping constant => ", agent.ω)
    println("Learning rate (η) => ", agent.η)
    println("Discount factor (γ) => ", agent.γ)
    println("Soft update (τ) => ", agent.τ)
    println("Exploration rate (ϵ) => ", agent.ϵ)
    println("ϵ decay => ", agent.ϵ_decay)
    println("ϵ min => ", agent.ϵ_min)
    println("batch size => ", agent.batch_size)
end

"""
    get_action(agent::DQNAgent, state::AbstractArray{<:Real}; nb_outputs=7)

Select ϵ-greedy action with exponential decay.

# Examples
```
julia> get_action(agent, state)
7-element Vector{Int64}:
 0  0  0  0  1  0  0
```
"""
function get_action(agent::DQNAgent, state::AbstractArray{<:Real}; nb_outputs=7)
    # Exploration modulated by epsilon with exponential decay
    exploration = agent.ϵ_min + (agent.ϵ - agent.ϵ_min) * exp(-1. * agent.n_games / agent.ϵ_decay)
    final_move = zeros(Int, nb_outputs)

    if rand() < exploration
        # Random move for exploration
        move = rand(1:nb_outputs)
        final_move[move] = 1
    else
        state = process_state(agent, state) |> device
        pred = agent.policy_net(state)
        pred = pred |> cpu
        final_move[Flux.onecold(pred)] = 1
    end

    return final_move
end

"""
    train!(
        agent::DQNAgent, 
        game::TetrisAI.Game.TetrisGame, 
        N::Int=100, 
        limit_updates::Bool=true, 
        render::Bool=true, 
        run_id::String="")

Train the agent for N episodes.
"""
function train!(
    agent::DQNAgent, 
    game::TetrisAI.Game.TetrisGame, 
    N::Int=100, 
    limit_updates::Bool=true, 
    render::Bool=true, 
    run_id::String="")

    benchmark = ScoreBenchMark(n=N)

    update_rate::Int64 = 1
    if limit_updates
        update_rate = max(round(N * 0.05), 1)
    end

    to_device!(agent)

    iter = ProgressBar(1:N)
    set_description(iter, "Training the agent on $N games:")

    for _ in iter
        done = false
        score = 0
        nb_ticks = 0
        ep_reward = 0.
        while !done
            # Get the current step
            raw_old_state = TetrisAI.Game.get_state(game)

            # Get the predicted move for the state
            action = get_action(agent, raw_old_state)            
            TetrisAI.send_input!(game, action)

            old_state = process_state(agent, raw_old_state)

            reward = 0.
            # Play the step
            lines, done, score = TetrisAI.Game.tick!(game)
            new_state = process_state(agent, TetrisAI.Game.get_state(game))

            # Adjust reward accoring to amount of lines cleared
            if done
                reward = -10.
            elseif agent.reward_shaping
                reward, agent.ω, agent.reward_shaping_score = shape_rewards(game, lines, agent.reward_shaping_score, agent.ω)
            else
                if lines > 0
                    reward = [1, 5, 10, 50][lines] |> f64
                end
            end

            # Push transition to replay buffer
            remember(agent, old_state, action, reward, new_state, done)

            experience_replay(agent)

            soft_target_update!(agent)

            if done
                # Reset the game
                TetrisAI.Game.reset!(game)
                agent.n_games += 1
                agent.record = max(score, agent.record)
            end

            ep_reward += reward
            nb_ticks = nb_ticks + 1
            if nb_ticks > 20000
                break
            end
        end

        append_score_ticks!(benchmark, score, nb_ticks, ep_reward)
        update_benchmark(benchmark, update_rate, iter, render)
    end

    save_to_csv(benchmark, agent.type, run_id)

    @info "Agent high score after $N games => $(agent.record) pts"
end

"""
    remember(
        agent::DQNAgent,
        state::Union{Array{Int64,3},Array{Float64,1}},
        action::Array{Int64,1},
        reward::Float64,
        next_state::Union{Array{Int64,3},Array{Float64,1}},
        done::Bool

Add an experience tuple ``e_t = (s_t, a_t, r_t, s_{t+1})`` to the replay buffer.
"""
function remember(
    agent::DQNAgent,
    state::Union{Array{Int64,3},Array{Float64,1}},
    action::Array{Int64,1},
    reward::Float64,
    next_state::Union{Array{Int64,3},Array{Float64,1}},
    done::Bool)
 
    transition = DQN_Transition(state, action, reward, next_state, done)
    push!(agent.memory, transition)
end

"""
    experience_replay(agent::DQNAgent)

Sample a minibatch from the replay buffer and to perform off-policy learning.
"""
function experience_replay(agent::DQNAgent)
    if length(agent.memory) > agent.batch_size
        mini_sample = sample(agent.memory, agent.batch_size)
    else
        mini_sample = agent.memory
    end

    states, actions, rewards, next_states, dones = map(x -> getfield.(mini_sample, x), fieldnames(eltype(mini_sample)))

    update!(agent, states, actions, rewards, next_states, dones)
end

"""
    soft_target_update!(agent::DQNAgent)

Perform soft target update à la DDPG.
"""
function soft_target_update!(agent::DQNAgent) 
    for (policy, target) ∈ zip(agent.policy_net, agent.target_net)
        if policy isa Conv || policy isa Dense
            target.weight .= agent.τ * policy.weight + (1 - agent.τ) * target.weight
            target.bias .= agent.τ * policy.bias + (1 - agent.τ) * target.bias
        end
    end
end

"""
    update!(
        agent::DQNAgent,
        state::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}},
        action::Vector{Array{Int64,1}},
        reward::Vector{Float64},
        next_state::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}},
        done::Union{Vector{Bool},BitVector}) 

Perform an update using a batch of transistions.
"""
function update!(
    agent::DQNAgent,
    state::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}},
    action::Vector{Array{Int64,1}},
    reward::Vector{Float64},
    next_state::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}},
    done::Union{Vector{Bool},BitVector}) 

    # Batching the states and converting data to Float32 (done implicitly otherwise)
    state = Flux.batch(state) |> x -> convert.(Float32, x) |> device
    next_state = Flux.batch(next_state) |> x -> convert.(Float32, x) |> device
    action = Flux.batch(action) |> x -> convert.(Float32, x)
    reward = Flux.batch(reward) |> x -> convert.(Float32, x)
    done = Flux.batch(done)

    # Model's prediction for next state
    ŷ = agent.target_net(next_state) 
    ŷ = ŷ |> cpu

    # Get the model's params for back propagation
    ps = Flux.params(agent.policy_net)

    # Calculate the gradients
    gs = Flux.gradient(ps) do
        # Forward pass
        y = agent.policy_net(state)
        y = y |> cpu

        # Creating buffer to allow mutability when calculating gradients
        Rₙ = Buffer(y, size(y))

        # Adjusting values of current state with next state's knowledge
        for idx in eachindex(done)
            # Copy preds into buffer
            Rₙ[:, idx] = y[:, idx]

            Qₙ = reward[idx] # target
            if done[idx] == false
                Qₙ += agent.γ * maximum(ŷ[:, idx])
            end

            # Adjusting the expected reward for selected move
            Rₙ[argmax(action[:, idx]), idx] = Qₙ
        end
        # Calculate the loss
        agent.loss(y |> device, copy(Rₙ) |> device)
    end

    # Update model weights
    Flux.Optimise.update!(agent.opt, ps, gs)
end

"""
    clone_behavior!(
        agent::DQNAgent, 
        lr::Float64 = 5e-4, 
        batch_size::Int64 = 50, 
        epochs::Int64 = 80)

Clone behavior from expert data to policy neural net
"""
function clone_behavior!(
    agent::DQNAgent, 
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)

    agent.policy_net = clone_behavior!(agent, agent.policy_net, Flux.params, lr , batch_size, epochs)

    agent.target_net = deepcopy(agent.policy_net)

    return agent
end

"""
    to_device!(agent::DQNAgent) 

Send the agent's model to cpu/cuda device.
"""
function to_device!(agent::DQNAgent) 
    agent.policy_net = agent.policy_net |> device
    agent.target_net = agent.target_net |> device
end

function sleep(agent::DQNAgent) 
    agent.memory = CircularBuffer{Int}(0)
end

function awake(agent::DQNAgent) 
    agent.memory = ReplayBuffer(DQN_Transition).data
end
