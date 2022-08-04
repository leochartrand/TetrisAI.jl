import GameZero: rungame
using ProgressBars

import TetrisAI: Game, MODELS_PATH
import TetrisAI.Agent: AbstractAgent

function play_tetris()
    rungame("src/player_game.jl")
end

function model_demo(name::AbstractString)

    model_path = joinpath(MODELS_PATH, string(name, ".bson"))

    ref_file = joinpath(MODELS_PATH, "current_model")

    if isfile(model_path)
        open(ref_file, "w") do file
            write(file, name)
        end

        rungame("src/model_game.jl")
    else
        print("Model not found.\n")
    end
end

function train_agent(agent::AbstractAgent; N::Int=100)

    # Creating the initial game
    game = TetrisGame()

    iter = ProgressBar(1:N)
    set_description(iter, "Training the agent on $N games:")

    for _ in iter
        done = false

        while !done
            done = train!(agent, game)
        end
    end

    @info "Agent high score after $N games => $(agent.record) pts"
end

function save_agent(name::AbstractString, agent::AbstractAgent)
    
    TetrisAI.Model.save_model(name, agent.model)

    return
end

function load_agent(name::AbstractString)
    
    agent = TetrisAgent()

    agent.model = TetrisAI.Model.load_model(name)

    return agent
end
