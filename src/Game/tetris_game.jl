"""
Representation of a tetris game
"""
Base.@kwdef mutable struct TetrisGame{T<:Integer} <: AbstractGame
    seed::T = 0
    is_over::Bool = false
    level::T = 1
    line_count::T = 0
    score::T = 0
    hold_piece::Union{AbstractTetromino, Nothing} = nothing
    bag::Bag = Bag()
    grid::Grid = Grid()
end