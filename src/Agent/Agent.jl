module Agent

import ..TetrisAI

import DataStructures: CircularBuffer
import Flux
import Flux: Dense, Conv
import CUDA
import StatsBase: sample
import Zygote: Buffer
import ..TetrisAI: MODELS_PATH

export AbstractAgent,
    RandomAgent,
    DQNAgent,
    train!,
    save,
    load,
    CNN_Transition,
    FE_Transition,
    CNN_ReplayBuffer,
    FE_ReplayBuffer,
    get_action,
    get_state_features,
    shape_rewards,
    clone_behavior!,
    to_device!,
    ScoreBenchMark


include("tetris_agent.jl")
include("memory.jl")
include("benchmark.jl")
include("extract_features.jl")
include("behavior_cloning.jl")
include("agents/dqn_agent.jl")
include("agents/ppo_agent.jl")

end # module