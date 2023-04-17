
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
get_action(agent::DQNAgent, state::AbstractArray{<:Integer}; nb_outputs=7)
```

```@docs
train!(agent::DQNAgent, game::TetrisAI.Game.TetrisGame, N::Int=100, limit_updates::Bool=true)
```

```@docs
Agent.remember(
    agent::DQNAgent,
    state::S,
    action::S,
    reward::T,
    next_state::S,
    done::Bool) where {T<:Integer,S<:AbstractArray{<:T}}
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
    state::Union{A,AA},
    action::Union{A,AA},
    reward::Union{T,AA},
    next_state::Union{A,AA},
    done::Union{Bool,AA}) where {T<:Integer,A<:AbstractArray{<:T},AA<:AbstractArray{A}}
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