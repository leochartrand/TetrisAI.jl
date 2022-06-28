"""
The Z_PIECE is an offset stack of horizontal 2-blocks lines with it's top line
protruding to the left.
"""
Base.@kwdef mutable struct Z_PIECE{T<:Integer} <: AbstractTetromino
    x::T = 2
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
