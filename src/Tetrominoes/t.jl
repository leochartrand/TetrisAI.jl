"""
The T_PIECE is an inverted T.
"""
Base.@kwdef mutable struct T_PIECE{T<:Integer} <: AbstractTetromino
    idx::T = 1
    shapes::Vector{Matrix{T}} = [
        [0 6 0
         6 6 6
         0 0 0],
         
        [0 6 0
         0 6 6
         0 6 0],

        [0 0 0
         6 6 6
         0 6 0],

        [0 6 0
         6 6 0
         0 6 0]
    ]
end

function Base.show(io::IO, p::T_PIECE)
    println("Piece type: T_PIECE")
    println("Color: Purple")
    println("Index: ", p.idx)
    for i = 1:4
        println(p.shapes[p.idx][i, :])
    end
end
