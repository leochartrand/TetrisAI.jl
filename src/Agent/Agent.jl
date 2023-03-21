module Agent

import ..TetrisAI

import DataStructures: CircularBuffer
import Flux
import CUDA
import StatsBase: sample
import Zygote: Buffer
import ..TetrisAI: MODELS_PATH

export AbstractAgent,
    RandomAgent,
    DQNAgent,
    SARSAAgent,
    train!,
    save,
    load!,
    CircularBufferMemory,
    get_action,
    get_state_features,
    shape_rewards,
    clone_behavior!,
    to_device!


include("memory.jl")
include("extract_features.jl")
include("behavioral_cloning.jl")
include("tetris_agent.jl")
include("agents/dqn_agent.jl")
include("agents/sarsa_agent.jl")
include("agents/ppo_agent.jl")
include("agents/sac_agent.jl")

end # module