"""
The O_PIECE is a square.
This piece is unique in the sense that it doesn't rotate
"""
Base.@kwdef mutable struct O_PIECE{T<:Integer} <: AbstractTetromino
    idx::T = 1
    shapes::Vector{Matrix{T}} = [
        [0 4 4 0
         0 4 4 0
         0 0 0 0],
        
        [0 4 4 0
         0 4 4 0
         0 0 0 0],
        
        [0 4 4 0
         0 4 4 0
         0 0 0 0],
        
        [0 4 4 0
         0 4 4 0
         0 0 0 0]
    ]
end

function Base.show(io::IO, p::O_PIECE)
    println("Piece type: O_PIECE")
    println("Color: Yellow")
    println("Index: ", p.idx)
    for i = 1:4
        println(p.shapes[p.idx][i, :])
    end
end
