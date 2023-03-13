using CUDA
import Flux: gpu, cpu

if CUDA.functional()
    CUDA.allowscalar(false)
    device = gpu
else
    device = cpu
end

function get_state(agent::AbstractAgent, game::TetrisAI.Game.AbstractGame)
    state = TetrisAI.Game.get_state(game)
    # agent.feature_extraction not implemented
    # if agent.feature_extraction
    #     state = get_state_features(state, game.active_piece.row, game.active_piece.col)
    # end
    return state
end

function train!(
    agent::AbstractAgent,
    game::TetrisAI.Game.AbstractGame,
    reward_cte::Float16,
    reward_last_score::Integer,
    do_shape::Bool = false
)

    # Get the current step
    old_state = get_state(agent, game)

    # Get the predicted move for the state
    move = get_action(agent, old_state)
    TetrisAI.send_input!(game, move)

    # Play the step
    lines, done, score = TetrisAI.Game.tick!(game)
    new_state = TetrisAI.Game.get_state(game) # NOTE: ici on avait get_game_state qui n'est pas défini nul part??

    # Adjust reward accoring to amount of lines cleared
    if do_shape
        reward, reward_last_score, reward_cte = shape_rewards(game, lines, reward_last_score, reward_cte)
    else
        if lines != 0
            reward = [1, 5, 10, 50][lines]
        end
    end

    # Train the short memory
    train_short_memory(agent, old_state, move, reward, new_state, done)

    # Remember
    remember(agent, old_state, move, reward, new_state, done)

    if done
        # Reset the game
        train_long_memory(agent)
        TetrisAI.Game.reset!(game)
        agent.n_games += 1

        if score > agent.record
            agent.record = score
        end
    end

    return done, score
end

function shape_rewards(
    game::TetrisAI.Game.AbstractGame,
    lines::Integer,
    last_score::Integer,
    cte::Float16
)
    reward = 0

    if lines > 0
        cte += 0.1
    end
    # Exploration to use an intermediate fitness function for early stages
    # Ref: http://cs231n.stanford.edu/reports/2016/pdfs/121_Report.pdf
    # As we score more and more lines, we change the scoring more and more to the
    # game's score instead of the intermediate rewards that are used only for the
    # early stages.
    reward += Int(round(((1 - cte) * computeIntermediateReward!(game.grid.cells, last_score, lines)) + (cte * (lines ^ 2))))


    return reward, last_score, cte
end

function train_memory(
    agent::TetrisAgent,
    old_state::S,
    move::S,
    reward::T,
    new_state::S,
    done::Bool
) where {T<:Integer,S<:AbstractArray{<:T}}
    # Train the short memory
    train_short_memory(agent, old_state, move, reward, new_state, done)
    # Remember
    remember(agent, old_state, move, reward, new_state, done)
    if done
        train_long_memory(agent)
    end
end

function remember(
    agent::TetrisAgent,
    state::S,
    action::S,
    reward::T,
    next_state::S,
    done::Bool
) where {T<:Integer,S<:AbstractArray{<:T}}
    push!(agent.memory.data, (state, action, [reward], next_state, convert.(Int, [done])))
end

function train_short_memory(
    agent::TetrisAgent,
    state::S,
    action::S,
    reward::T,
    next_state::S,
    done::Bool
) where {T<:Integer,S<:AbstractArray{<:T}}
    update!(agent, state, action, reward, next_state, done)
end

function train_long_memory(agent::TetrisAgent)
    if length(agent.memory.data) > BATCH_SIZE
        mini_sample = sample(agent.memory.data, BATCH_SIZE)
    else
        mini_sample = agent.memory.data
    end

    states, actions, rewards, next_states, dones = map(x -> getfield.(mini_sample, x), fieldnames(eltype(mini_sample)))

    update!(agent, states, actions, rewards, next_states, dones)
end

function get_action(agent::AbstractAgent, state::AbstractArray{<:Integer}; rand_range=1:200, nb_outputs=7)
    agent.ϵ = 80 - agent.n_games
    final_move = zeros(Int, nb_outputs)

    if rand(rand_range) < agent.ϵ
        # Random move for exploration
        move = rand(1:nb_outputs)
        final_move[move] = 1
    else
        state = state |> device
        pred = agent.model(state)
        pred = pred |> cpu
        final_move[Flux.onecold(pred)] = 1
    end

    return final_move
end

function update!(
    agent::TetrisAgent,
    state::Union{A,AA},
    action::Union{A,AA},
    reward::Union{T,AA},
    next_state::Union{A,AA},
    done::Union{Bool,AA};
    α::Float32=0.9f0    # Step size
) where {T<:Integer,A<:AbstractArray{<:T},AA<:AbstractArray{A}}
    # No criterion for random model
    if agent.opt === nothing
        return
    end

    # Batching the states and converting data to Float32 (done implicitly otherwise)
    state = Flux.batch(state) |> x -> convert.(Float32, x) |> device
    next_state = Flux.batch(next_state) |> x -> convert.(Float32, x) |> device
    action = Flux.batch(action) |> x -> convert.(Float32, x)
    reward = Flux.batch(reward) |> x -> convert.(Float32, x)
    done = Flux.batch(done)

    # Model's prediction for next state
    y = agent.model(next_state) 
    y = y |> cpu

    # Get the model's params for back propagation
    ps = Flux.params(agent.model)

    # Calculate the gradients
    gs = Flux.gradient(ps) do
        # Forward pass
        ŷ = agent.model(state)
        ŷ = ŷ |> cpu

        # Creating buffer to allow mutability when calculating gradients
        Rₙ = Buffer(ŷ, size(ŷ))

        # Adjusting values of current state with next state's knowledge
        for idx in 1:length(done)
            # Copy preds into buffer
            Rₙ[:, idx] = ŷ[:, idx]

            Qₙ = reward[idx]
            if done[idx] == false
                Qₙ += α * maximum(y[:, idx])
            end

            # Adjusting the expected reward for selected move
            Rₙ[argmax(action[:, idx]), idx] = Qₙ
        end
        # Calculate the loss
        agent.criterion(ŷ |> device, copy(Rₙ) |> device)
    end

    # Update model weights
    Flux.Optimise.update!(agent.opt, ps, gs)
end
