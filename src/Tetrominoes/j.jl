"""
The J_PIECE is a 3-long straight bar with a block on it's left.
"""
Base.@kwdef mutable struct J_PIECE{T<:Integer} <: AbstractTetromino
    id::T = 2
    x::T = 2
    y::T = 4
    idx::T = 1
    shapes::Vector{Matrix{T}} = [
        [2 0 0
         2 2 2
         0 0 0],
        
        [0 2 2
         0 2 0
         0 2 0],
        
        [0 0 0
         2 2 2
         0 0 2],
         
        [0 2 0
         0 2 0
         2 2 0],
    ]
end
