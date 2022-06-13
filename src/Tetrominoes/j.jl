"""
The J_PIECE is a 3-long straight bar with a block on it's left.
"""
Base.@kwdef mutable struct J_PIECE{T<:Integer} <: AbstractTetromino
    idx::T = 1
    shapes::Vector{Matrix{T}} = [
        [2 0 0
         2 2 2
         0 0 0],
        
        [0 2 2
         0 2 0
         0 2 0],
        
        [0 0 0
         2 2 2
         0 0 2],
         
        [0 2 0
         0 2 0
         2 2 0],
    ]
end

function Base.show(io::IO, p::J_PIECE)
    println("Piece type: J_PIECE")
    println("Color: Blue")
    println("Index: ", p.idx)
    for i = 1:4
        println(p.shapes[p.idx][i, :])
    end
end

"""
Rotates the piece counter clockwise
"""
function rotate_left!(p::I_PIECE)
    p.idx == 1 ? p.idx = 4 : p.idx -= 1
    return
end

"""
Rotates the piece clockwise
"""
function rotate_right!(p::I_PIECE) 
    p.idx == 4 ? p.idx = 1 : p.idx += 1
    return
end