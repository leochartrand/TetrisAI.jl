"""
The T_PIECE is an inverted T.
"""
Base.@kwdef mutable struct T_PIECE{T<:Integer} <: AbstractTetromino
    x::T = 19
    y::T = 4
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
    println("Position: ($(p.x), $(p.y))")
    println("Color: Purple")
    println("Index: ", p.idx)
    for i = 1:3
        println(p.shapes[p.idx][i, :])
    end
end
