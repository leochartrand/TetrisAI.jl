"""
The I_PIECE is a long straight bar composed of 4 blocks.
This piece is the only piece capable of producing a tetris when dropped.

The blocks numbers are in the following form:
    [1]
    [2]
    [3]
    [4]
"""
Base.@kwdef mutable struct I_PIECE <: AbstractTetromino
    Color::RGB = COLORS_DICT["Cyan"]
    Coords::Vector{Block} = [
        Block(STARTING_X_POS, STARTING_Y_POS),
        Block(STARTING_X_POS, STARTING_Y_POS + BLOCK_SIZE),
        Block(STARTING_X_POS, STARTING_Y_POS + 2 * BLOCK_SIZE),
        Block(STARTING_X_POS, STARTING_Y_POS + 3 * BLOCK_SIZE)
    ]
end

function Base.show(io::IO, p::I_PIECE)
    println("Piece type: I_PIECE")
    println("Color: Cyan")
    print("Coords: [")
    print(p.Coords[1], ", ")
    print(p.Coords[2], ", ")
    print(p.Coords[3], ", ")
    print(p.Coords[4], "]")
end

"""
Rotates the piece I_PIECE according to it's orientation.

I_PIECES have two rotations, favoring the lower half when horizontal, 
and the right half when vertical.
"""
function rotate!(p::I_PIECE)
    # Check if the piece is vertical
    if (p.Coords[1].x == p.Coords[2].x)
        # Rotating first block
        p.Coords[1].x -= 2 * BLOCK_SIZE
        p.Coords[1].y += 2 * BLOCK_SIZE
        # Rotating second block
        p.Coords[2].x -= BLOCK_SIZE
        p.Coords[2].y += BLOCK_SIZE
        # Rotating fourth block
        p.Coords[4].x += BLOCK_SIZE
        p.Coords[4].y -= BLOCK_SIZE
    else
        # Rotating first block
        p.Coords[1].x += 2 * BLOCK_SIZE
        p.Coords[1].y -= 2 * BLOCK_SIZE
        # Rotating second block
        p.Coords[2].x += BLOCK_SIZE
        p.Coords[2].y -= BLOCK_SIZE
        # Rotating fourth block
        p.Coords[4].x -= BLOCK_SIZE
        p.Coords[4].y += BLOCK_SIZE    
    end
    return p
end

# Same rotation regardless of function call
rotate_left!(p::I_PIECE) = rotate!(p::I_PIECE)
rotate_right!(p::I_PIECE) = rotate!(p::I_PIECE)
