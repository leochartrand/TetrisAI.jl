module TetrisAI
    
using GameZero

export play_tetris, model_demo, collect_data, pretrain_agent, train_agent, save_agent, load_agent, download_data

const PROJECT_ROOT = pkgdir(@__MODULE__)

include("Utils/Utils.jl")
using .Utils
export MODELS_PATH

include("Tetrominoes/Tetrominoes.jl")
using .Tetrominoes
export I_PIECE, J_PIECE, L_PIECE, O_PIECE, S_PIECE, T_PIECE, Z_PIECE

include("Game/Game.jl")
using .Game
export TetrisGame, send_input!, tick!, reset!, get_preview_pieces, get_state

include("Model/Model.jl")
using .Model
export random_Net, load_model, save_model

include("Agent/Agent.jl")
using .Agent
export AbstractAgent, RandomAgent, to_device!, DQNAgent

include("GUI/GUI.jl")
using .GUI
export TetrisUI

include("functions.jl")

end
