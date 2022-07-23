module TetrisAI
    
using GameZero

export run_tetris

const PROJECT_ROOT = pkgdir(@__MODULE__)

include("Utils/Utils.jl")
using .Utils
export MODELS_PATH

include("Tetrominoes/Tetrominoes.jl")
using .Tetrominoes
export I_PIECE, J_PIECE, L_PIECE, O_PIECE, S_PIECE, T_PIECE, Z_PIECE

include("Game/Game.jl")
using .Game
export TetrisGame, send_input!, play_step!, reset!, get_preview_pieces

include("Model/Model.jl")
using .Model

include("Agent/Agent.jl")
using .Agent
export TetrisAgent

include("functions.jl")

end
