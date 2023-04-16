
# SARSA AGENT
```@meta
CurrentModule = TetrisAI
```

```@docs
get_action(agent::SARSAAgent, state::AbstractArray{<:Real}, nb_outputs::Integer=7)
```

```@docs
train!(agent::SARSAAgent, game::TetrisAI.Game.AbstractGame)
```

```@docs
Agent.update!(
        agent::SARSAAgent,
        state::Union{A,AA},
        action::Union{A,AA},
        reward::Union{T,AA},
        next_state::Union{A,AA},
        done::Union{Bool,AA};
        α::Float32=0.9f0) where {T<:Real,A<:AbstractArray{<:T},AA<:AbstractArray{A}}
```

```@docs
clone_behavior!(
        agent::SARSAAgent,
        lr::Float64 = 5e-4, 
        batch_size::Int64 = 50, 
        epochs::Int64 = 80)
```

```@docs
to_device!(agent::SARSAAgent)
```