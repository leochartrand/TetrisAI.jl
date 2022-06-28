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
