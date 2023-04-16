
# DQN AGENT
```@meta
CurrentModule = TetrisAI
```

```@docs
get_action(agent::DQNAgent, state::AbstractArray{<:Integer}; rand_range=1:200, nb_outputs=7)
```

```@docs
train!(agent::DQNAgent, game::TetrisAI.Game.AbstractGame)
```

```@docs
Agent.train_memory(
    agent::DQNAgent, 
    old_state::S, 
    move::S, 
    reward::T, 
    new_state::S, 
    done::Bool) where {T<:Integer,S<:AbstractArray{<:T}}
```

```@docs
Agent.remember(
    agent::DQNAgent,
    state::S,
    action::S,
    reward::T,
    next_state::S,
    done::Bool
) where {T<:Integer,S<:AbstractArray{<:T}}
```

```@docs
Agent.train_short_memory(
    agent::DQNAgent,
    state::S,
    action::S,
    reward::T,
    next_state::S,
    done::Bool
) where {T<:Integer,S<:AbstractArray{<:T}}
```

```@docs
Agent.train_long_memory(agent::DQNAgent)
```

```@docs
Agent.update!(
    agent::DQNAgent,
    state::Union{A,AA},
    action::Union{A,AA},
    reward::Union{T,AA},
    next_state::Union{A,AA},
    done::Union{Bool,AA};
    α::Float32=0.9f0    # Step size
) where {T<:Integer,A<:AbstractArray{<:T},AA<:AbstractArray{A}}
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