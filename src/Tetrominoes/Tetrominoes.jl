module Tetrominoes

export I_PIECE, J_PIECE, L_PIECE, O_PIECE, S_PIECE, T_PIECE, 
    Z_PIECE, move_left!, move_right!, drop!, rotate_clockwise!, 
    rotate_counter_clockwise!, get_random_piece

include("Moves.jl")
import .Moves: move_left!, move_right!, drop!, rotate_clockwise!, rotate_counter_clockwise!

include("types.jl")
include("functions.jl")

end # module 