module TetrisAI
    
using GameZero

export run_tetris

# include("Utils/Utils.jl")
# using .Utils
# export Block, BLOCK_SIZE, STARTING_X_POS, STARTING_Y_POS, COLORS_DICT

include("Tetrominoes/Tetrominoes.jl")
using .Tetrominoes
export I_PIECE, J_PIECE, L_PIECE, O_PIECE, S_PIECE, T_PIECE, Z_PIECE

include("Game/Game.jl")
using .Game
export TetrisGame, send_input!, play_step!, reset!


function run_tetris()
    rungame("src/game.jl")
end

end
