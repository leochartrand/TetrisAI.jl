module TetrisAI

include("Utils/Utils.jl")
using .Utils
export Block, BLOCK_SIZE, STARTING_X_POS, STARTING_Y_POS, COLORS_DICT

include("Tetrominoes/Tetrominoes.jl")
using .Tetrominoes
export rotate_left!, rotate_right!

include("Game/Game.jl")
using .Game
export TetrisGame

end
