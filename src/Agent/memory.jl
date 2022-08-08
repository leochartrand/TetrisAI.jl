const MemoryData = NTuple{5,Vector{Int}}

abstract type AgentMemory end

Base.@kwdef struct CircularBufferMemory <: AgentMemory
    data::CircularBuffer = CircularBuffer{MemoryData}(100_000)
end
