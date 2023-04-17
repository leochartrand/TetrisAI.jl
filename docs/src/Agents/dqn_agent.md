
# DQN AGENT
```@meta
CurrentModule = TetrisAI
```

```@docs
DQNAgent
```

```@docs
Base.show(io::IO, agent::DQNAgent)
```

```@docs
get_action(agent::DQNAgent, state::AbstractArray{<:Real}; nb_outputs=7)
```

```@docs
train!(
    agent::DQNAgent, 
    game::TetrisAI.Game.TetrisGame, 
    N::Int=100, 
    limit_updates::Bool=true, 
    render::Bool=true, 
    run_id::String="")
```

```@docs
Agent.remember(
        agent::DQNAgent,
        state::Union{Array{Int64,3},Array{Float64,1}},
        action::Array{Int64,1},
        reward::Int64,
        next_state::Union{Array{Int64,3},Array{Float64,1}},
        done::Bool)
```

```@docs
Agent.experience_replay(agent::DQNAgent)
```

```@docs
Agent.soft_target_update!(agent::DQNAgent)
```

```@docs
Agent.update!(
    agent::DQNAgent,
    state::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}},
    action::Vector{Array{Int64,1}},
    reward::Vector{Int64},
    next_state::Union{Vector{Array{Int64,3}},Vector{Array{Float64,1}}},
    done::Union{Vector{Bool},BitVector}) 
```

```@docs
clone_behavior!(
    agent::DQNAgent, 
    lr::Float64 = 5e-4, 
    batch_size::Int64 = 50, 
    epochs::Int64 = 80)
```

```@docs
to_device!(agent::DQNAgent)
```