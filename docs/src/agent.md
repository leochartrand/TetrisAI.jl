# Agents
This section covers the different available agent types and their related functionnalities

```@meta
CurrentModule = TetrisAI
```

## tetris_agent.jl
```@docs
Base.show(io::IO, agent::AbstractAgent)
```

```@docs
get_action(agent::AbstractAgent, nb_outputs::Integer=7)
```

```@docs
train!(agent::AbstractAgent, game::TetrisAI.Game.AbstractGame)
```

```@docs
to_device!(agent::AbstractAgent)
```

```@docs
clone_behavior!(
    agent::AbstractAgent, 
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)
```

```@docs
save(agent::AbstractAgent, name::AbstractString=nothing)
```

```@docs
load(name::AbstractString)
```

## behavioral_cloning.jl
```@docs
clone_behavior!(
    agent::AbstractAgent,
    model,
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)
```

## benchmark.jl

```@docs
Agent.append_score_ticks!(b::ScoreBenchMark, score::Int64, tick::Int64, reward::Int64 = 0)
```

```@docs
Agent.update_benchmark
```

```@docs
Agent.save_to_csv(benchmark::ScoreBenchMark, filename::String, verbose::Bool = false)
```

## extract_features.jl
```@docs
Agent.get_column_heights(g::Matrix{Int})
```

```@docs
Agent.get_bumpiness(g::Matrix{Int})
```

```@docs
Agent.get_bumpiness(heights::AbstractArray{Int})
```

```@docs
Agent.is_in_visible_grid(row, col)
```

```@docs
Agent.flood_cell(raw_grid::Matrix{Int}, feature_grid::Matrix{Int}, row, col, target, value)
```

```@docs
Agent.get_fall_height(g::Matrix{Int}, active_piece_row::Int, active_piece_col::Int)
```

```@docs
Agent.get_n_holes(feature_grid::Matrix{Int})
```

```@docs
Agent.get_active_piece_pos(raw_grid::Matrix{Int})
```

```@docs
Agent.get_feature_grid(raw_grid::Matrix{Int})
```

```@docs
Agent.print_cell(value)
```

```@docs
Agent.print_grids(raw_grid,feature_grid)
```

```@docs
get_state_features(state::Vector{Int}, active_piece_row::Int, active_piece_col::Int)
```

```@docs
get_state_features(state::Vector{Int})
```

```@docs
Agent.computeIntermediateReward(game_grid::Matrix{Int}, last_score::Integer, lines::Int)
```

```@docs
shape_rewards(game::TetrisAI.Game.AbstractGame, lines::Integer)
```



