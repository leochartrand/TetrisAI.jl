module Agent

import ..TetrisAI

import DataStructures: CircularBuffer
import Flux
import CUDA
import StatsBase: sample
import Zygote: Buffer

export TetrisAgent,
    RandomAgent,
    train!,
    CircularBufferMemory,
    get_action,
    train_memory,
    get_state_features

include("memory.jl")
include("agents.jl")
include("functions.jl")
include("extract_features.jl")

end # module