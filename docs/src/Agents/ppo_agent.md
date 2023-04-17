# PPO AGENT

```@meta
CurrentModule = TetrisAI
```

```@docs
BufferKeys
```

```@docs
PPOAgent
```

```@docs
get_action(agent::PPOAgent, state::Vector, nb_outputs::Integer=7)
```

```@docs
Agent.rollout(agent::PPOAgent, game::TetrisAI.Game.AbstractGame)
```

```@docs
train!(agent::PPOAgent, game::TetrisAI.Game.TetrisGame, N::Int=100, limit_updates::Bool=true)
```

```@docs
Agent.calculate_gaes(rewards::Vector, values::Vector, γ::Float32, decay::Float32)
```

```@docs
Agent.discount_reward(rewards::Vector{<:Float32}, γ::Float32)
```

```@docs
Agent.policy_forward(agent::PPOAgent, state::Union{Vector, Matrix})
```

```@docs
Agent.value_forward(agent::PPOAgent, state::Union{Vector, Matrix})
```

```@docs
forward(agent::PPOAgent, state::Union{Vector, Matrix})
```

```@docs
Agent.train_policy!(agent::PPOAgent, states::Vector, acts::Vector, old_log_probs::Vector, gaes::Vector, returns::Vector)
```

```@docs
Agent.train_value!(agent::PPOAgent, returns::Vector{Float32})
```

```@docs
clone_behavior!(agent::PPOAgent)
```

```@docs
to_device!(agent::PPOAgent)
```