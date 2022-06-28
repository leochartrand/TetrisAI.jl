"""
Output on IO of current object
"""
function Base.show(io::IO, t::AbstractTetromino)
    println("Piece type: $(typeof(t))")
    println("Position: ($(t.x), $(t.y))")
    println("Index: ", t.idx)
    # Iterate over the rows of a piece
    for row in 1:size(t.shapes[t.idx], 1)
        println(t.shapes[t.idx][row, :])
    end
end

"""
Rotates a piece counter-clockwise
"""
function rotate_left!(t::AbstractTetromino)
    t.idx == 1 ? t.idx = 4 : t.idx -= 1
    return
end

"""
Rotates the piece clockwise
"""
function rotate_right!(t::AbstractTetromino) 
    t.idx == 4 ? t.idx = 1 : t.idx += 1
    return
end

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
    piece = PIECE_TYPES[rand(1:length(PIECE_TYPES))]

    return getfield(Main.TetrisAI.Tetrominoes, piece)()
end