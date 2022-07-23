module Agent

import ..TetrisAI

import DataStructures: CircularBuffer
import Flux
import StatsBase: sample
import Zygote: Buffer

export TetrisAgent,
    train!,
    CircularBufferMemory

include("memory.jl")
include("agents.jl")
include("functions.jl")

end # module