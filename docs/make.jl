using Pkg
pkg"activate .."

using Documenter
using TetrisAI

DocMeta.setdocmeta!(TetrisAI, :DocTestSetup, :(using TetrisAI); recursive=true)

makedocs(;
    modules=[TetrisAI],
    authors="cleg1805 <cleg1805@usherbrooke.ca>, chal2525 <chal2525@usherbrooke.ca>",
    repo="https://depot.dinf.usherbrooke.ca//cleg1805/TetrisAI.jl/blob/{commit}{path}#{line}",
    sitename="TetrisAI.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cleg1805.gitlab.io/TetrisAI.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Agent" => Any[
            "Agent/index.md",
            "Agent/behavioral_cloning.md",
            "Agent/dqn_agent.md",
            "Agent/extract_features.md",
            "Agent/ppo_agent.md",
            "Agent/sac_agent.md",
            "Agent/sarsa_agent.md",
            "Agent/tetris_agent.md"
        ],
        "Game" => "game.md",
        "GUI" => "gui.md",
        "Model" => "model.md",
        "Tetrominoes" => "tetrominoes.md",
        "Utils" => "utils.md"
    ],
)
