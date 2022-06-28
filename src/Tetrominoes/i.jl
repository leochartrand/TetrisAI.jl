"""
The I_PIECE is a long straight bar.
This piece is the only piece capable of producing a tetris when dropped.
"""
Base.@kwdef mutable struct I_PIECE{T<:Integer} <: AbstractTetromino
    x::T = 2
    y::T = 4
    idx::T = 1
    shapes::Vector{Matrix{T}} = [
        [0 0 0 0
         1 1 1 1
         0 0 0 0
         0 0 0 0],
        
        [0 0 1 0
         0 0 1 0
         0 0 1 0
         0 0 1 0],
        
        [0 0 0 0
         0 0 0 0
         1 1 1 1
         0 0 0 0],
         
        [0 1 0 0
         0 1 0 0
         0 1 0 0
         0 1 0 0]
    ]
end
