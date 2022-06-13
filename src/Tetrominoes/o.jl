"""
The O_PIECE is a square.
This piece is unique in the sense that it doesn't rotate
"""
Base.@kwdef mutable struct O_PIECE{T<:Integer} <: AbstractTetromino
     x::T = 19
    y::T = 4
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
    println("Position: ($(p.x), $(p.y))")
    println("Color: Yellow")
    println("Index: ", p.idx)
    for i = 1:3
        println(p.shapes[p.idx][i, :])
    end
end
