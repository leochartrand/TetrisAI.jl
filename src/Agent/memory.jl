abstract type AbstractTransition end

Base.@kwdef struct DQN_Transition <: AbstractTransition
    state::Union{Array{Int64,3},Array{Float64,1}}
    action::Array{Int64,1}
    reward::Int64
    new_state::Union{Array{Int64,3},Array{Float64,1}}
    done::Bool
end

Base.@kwdef struct PPO_Transition <: AbstractTransition
    state::Union{Array{Int64,3},Array{Float64,1}}
    action::Array{Int64,1}
    reward::Int64
    log_probs::Array{Float64,1}
    gae::Union{Array{Int64,3},Array{Float64,1}}
    value::Float64
    done::Bool
end

abstract type AgentMemory end

Base.@kwdef struct ReplayBuffer <: AgentMemory
    type
    data::CircularBuffer
    ReplayBuffer(t::Type{A}) where {A <: AbstractTransition} = new(t,CircularBuffer{t}(100_000))
end
