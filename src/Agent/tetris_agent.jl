# AbstractAgent interface
abstract type AbstractAgent end

Base.@kwdef mutable struct RandomAgent <: AbstractAgent
    n_games::Int = 0
    record::Int = 0
    model = TetrisAI.Model.random_Net(7)
end

function Base.show(io::IO, agent::AbstractAgent)
    println("n_games => ", agent.n_games)
    println("record => ", agent.record)
end

function get_action(agent::AbstractAgent, nb_outputs=7)
    final_move = zeros(Int, nb_outputs)
    move = rand(1:nb_outputs)
    final_move[move] = 1

    return final_move
end

function train!(agent::AbstractAgent, game::TetrisAI.Game.AbstractGame)

    # Get the current step
    old_state = TetrisAI.Game.get_state(game)

    # Get the predicted move for the state
    move = get_action(agent, old_state)
    TetrisAI.send_input!(game, move)

    # Play the step
    _, done, score = TetrisAI.Game.tick!(game)

    if done
        # Reset the game
        TetrisAI.Game.reset!(game)
        agent.n_games += 1

        if score > agent.record
            agent.record = score
        end
    end

    return done, score
end

function clone_behavior!(agent::AbstractAgent, lr::Float64 = 5e-4, batch_size::Int64 = 50, epochs::Int64 = 80) end

function save(agent::AbstractAgent, name::AbstractString) end

function load!(agent::AbstractAgent, name::AbstractString)
    return agent
end
