module TetrisAI

include("Utils/Utils.jl")
using .Utils
export Block, BLOCK_SIZE, STARTING_X_POS, STARTING_Y_POS, COLORS_DICT

include("Tetrominos/Tetrominos.jl")
using .Tetrominos
export move_left!, move_right!, drop!, rotate_left!, rotate_right!

end
