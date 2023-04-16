module Game

import ..TetrisAI

export TetrisGame, send_input!, get_state, tick!, reset!, get_preview_pieces, convert_input_to_vector, COLORS

include("moves.jl")
include("tetrominoes.jl")
include("functions.jl")
include("bag.jl")
include("grid.jl")
include("tetris_game.jl")

end