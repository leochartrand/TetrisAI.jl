abstract type AbstractTransition end

Base.@kwdef struct CNN_Transition <: AbstractTransition
    state::Array{Int64,3}
    action::Array{Int64,1}
    reward::Int64
    new_state::Array{Int64,3}
    done::Bool
end

Base.@kwdef struct FE_Transition <: AbstractTransition
    state::Array{Float64,1}
    action::Array{Int64,1}
    reward::Int64
    new_state::Array{Float64,1}
    done::Bool
end

abstract type AgentMemory end

Base.@kwdef struct CNN_ReplayBuffer <: AgentMemory
    data::CircularBuffer = CircularBuffer{CNN_Transition}(100_000)
end

Base.@kwdef struct FE_ReplayBuffer <: AgentMemory
    data::CircularBuffer = CircularBuffer{FE_Transition}(100_000)
end
