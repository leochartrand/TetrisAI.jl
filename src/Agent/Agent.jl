module Agent

import ..TetrisAI

import DataStructures: CircularBuffer
import Flux
import StatsBase: sample
import Zygote: Buffer

export TetrisAgent,
    RandomAgent,
    train!,
    CircularBufferMemory,
    get_action,
    train_memory

include("memory.jl")
include("agents.jl")
include("functions.jl")

end # module