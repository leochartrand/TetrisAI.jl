"""
The Z_PIECE is an offset stack of horizontal 2-blocks lines with it's top line
protruding to the left.
"""
Base.@kwdef mutable struct Z_PIECE{T<:Integer} <: AbstractTetromino
    x::T = 19
    y::T = 4
    idx::T = 1
    shapes::Vector{Matrix{T}} = [
        [7 7 0
         0 7 7
         0 0 0],
         
        [0 0 7
         0 7 7
         0 7 0],

        [0 0 0
         7 7 0
         0 7 7],

        [0 7 0
         7 7 0
         7 0 0]
    ]
end

function Base.show(io::IO, p::Z_PIECE)
    println("Piece type: Z_PIECE")
    println("Color: Cyan")
    println("Index: ", p.idx)
    for i = 1:4
        println(p.shapes[p.idx][i, :])
    end
end
