module TetrisAI

using Colors

export I_PIECE, O_PIECE, move_left!, move_right!, drop!, rotate_left!, 
    rotate_right!

include("Utils/Utils.jl")
include("Tetrominos/Tetrominos.jl")

end
