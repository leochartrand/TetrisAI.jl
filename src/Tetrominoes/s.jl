"""
The S_PIECE is an offset stack of horizontal 2-blocks lines with it's top line
protruding to the right.
"""
Base.@kwdef mutable struct S_PIECE{T<:Integer} <: AbstractTetromino
    x::T = 19
    y::T = 4
    idx::T = 1
    shapes::Vector{Matrix{T}} = [
        [0 5 5
         5 5 0
         0 0 0],
         
        [0 5 0
         0 5 5
         0 0 5],

        [0 0 0
         0 5 5
         5 5 0],

        [5 0 0
         5 5 0
         0 5 0]
    ]
end

function Base.show(io::IO, p::S_PIECE)
    println("Piece type: S_PIECE")
    println("Position: ($(p.x), $(p.y))")
    println("Color: Green")
    println("Index: ", p.idx)
    for i = 1:3
        println(p.shapes[p.idx][i, :])
    end
end
