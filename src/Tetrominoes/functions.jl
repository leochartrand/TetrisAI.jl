"""
Get a piece randomly meta-programming style
"""
function get_random_piece()
    local PIECE_TYPES = [
        :I_PIECE,
        :J_PIECE,
        :L_PIECE,
        :O_PIECE,
        :S_PIECE,
        :T_PIECE,
        :Z_PIECE
    ]
    # This random call is seeded in the TetrisGame composite type
    return getfield(@__MODULE__, rand(PIECE_TYPES))()
end