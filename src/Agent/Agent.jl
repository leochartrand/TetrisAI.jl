module Agent

import ..TetrisAI

import DataStructures: CircularBuffer
import Flux
import CUDA
import StatsBase: sample
import Zygote: Buffer

export TetrisAgent,
    RandomAgent,
    DQNAgent,
    SarsaAgent,
    train!,
    save,
    load!,
    CircularBufferMemory,
    get_action,
    get_state_features,
    shape_rewards

include("memory.jl")
include("extract_features.jl")
include("tetris_agent.jl")
include("agents/dqn_agent.jl")
include("agents/sarsa_agent.jl")
include("agents/ppo_agent.jl")
include("agents/sac_agent.jl")

end # module