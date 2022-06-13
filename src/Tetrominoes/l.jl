"""
The L_PIECE is a 3-long straight bar with a block on it's right.
"""
Base.@kwdef mutable struct L_PIECE{T<:Integer} <: AbstractTetromino
    x::T = 19
    y::T = 4
    idx::T = 1
    shapes::Vector{Matrix{T}} = [
        [0 0 3
         3 3 3
         0 0 0],
        
        [0 3 0
         0 3 0
         0 3 3],
        
        [0 0 0
         3 3 3
         3 0 0],
         
        [3 3 0
         0 3 0
         0 3 0],
    ]
end

function Base.show(io::IO, p::L_PIECE)
    println("Piece type: L_PIECE")
    println("Position: ($(p.x), $(p.y))")
    println("Color: Orange")
    println("Index: ", p.idx)
    for i = 1:3
        println(p.shapes[p.idx][i, :])
    end
end
