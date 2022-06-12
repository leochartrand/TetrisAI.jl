"""
The O_PIECE is a squared piece composed of 4 blocks.

The blocks numbers are in the following form:
    [1][2]
    [3][4]
"""
Base.@kwdef mutable struct O_PIECE <: AbstractTetromino
    Color::RGB = COLORS_DICT["Yellow"]
    Coords::Vector{Block} = [
        Block(STARTING_X_POS, STARTING_Y_POS),
        Block(STARTING_X_POS + BLOCK_SIZE, STARTING_Y_POS),
        Block(STARTING_X_POS, STARTING_Y_POS + BLOCK_SIZE),
        Block(STARTING_X_POS + BLOCK_SIZE, STARTING_Y_POS + BLOCK_SIZE)
    ]
end

function Base.show(io::IO, p::O_PIECE)
    println("Piece type: O_PIECE")
    println("Color: Yellow")
    print("Coords: [")
    print(p.Coords[1], ", ")
    print(p.Coords[2], ", ")
    print(p.Coords[3], ", ")
    print(p.Coords[4], "]")
end

"""
The O_PIECE can't rotate
"""
rotate_left!(p::O_PIECE) = return p

"""
The O_PIECE can't rotate
"""
rotate_right!(p::O_PIECE) = return p
