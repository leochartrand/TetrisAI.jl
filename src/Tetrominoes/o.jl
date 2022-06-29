"""
The O_PIECE is a square.
This piece is unique in the sense that it doesn't rotate
"""
Base.@kwdef mutable struct O_PIECE{T<:Integer} <: AbstractTetromino
    id::T = 4
    x::T = 2
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
