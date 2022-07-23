import GameZero: rungame
using ProgressBars

import TetrisAI: Game
import TetrisAI.Agent: AbstractAgent

function run_tetris()
    rungame("src/game.jl")
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