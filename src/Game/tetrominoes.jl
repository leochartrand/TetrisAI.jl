"""
Represents a game piece composed of 4 blocks.

All subtypes should implement the Moves interface.
"""
abstract type AbstractTetromino end

"""
    Base.show(io::IO, t::AbstractTetromino)

Output on IO of current object
"""
function Base.show(io::IO, t::AbstractTetromino)
    println("Piece type: $(typeof(t))")
    println("Position: ($(t.row), $(t.col))")

    # Iterate over the rows of a piece
    for row in 1:size(t, 1)
        println(t[row, :])
    end
end

"""
    Base.size(t::AbstractTetromino, d...)

Get the size of a tetromino's shape
"""
function Base.size(t::AbstractTetromino, d...)
    size(t.shapes[1], d...)
end

"""
    Base.getindex(t::AbstractTetromino, I...)

Get index of a piece redirects directly to it's shape
"""
function Base.getindex(t::AbstractTetromino, I...)
    getindex(t.shapes[t.state], I...)
end

"""
    Base.setindex!(t::AbstractTetromino, I...)

Set index of a piece redirects directly to it's shape
"""
function Base.setindex!(t::AbstractTetromino, I...)
    setindex!(t.shapes[t.state], I...)
end

"""
    shape(t::AbstractTetromino)

Get the current shape of a tetromino
"""
function shape(t::AbstractTetromino)
    t.shapes[t.state]
end

"""
    move_left!(t::AbstractTetromino)

Moves the tetromino one block to the left
"""
function move_left!(t::AbstractTetromino)
    t.col -= 1
    return
end

"""
    move_right!(t::AbstractTetromino)

Moves the tetromino one block to the right
"""
function move_right!(t::AbstractTetromino)
    t.col += 1
    return
end

"""
    drop!(t::AbstractTetromino)

Drops the tetromino down once.
"""
function drop!(t::AbstractTetromino)
    t.row += 1
    return
end

"""
    rotate_clockwise!(t::AbstractTetromino)

Rotates the piece clockwise
"""
function rotate_clockwise!(t::AbstractTetromino)
    t.state == 4 ? t.state = 1 : t.state += 1
    return
end

"""
    rotate_counter_clockwise!(t::AbstractTetromino)

Rotates a piece counter-clockwise
"""
function rotate_counter_clockwise!(t::AbstractTetromino)
    t.state == 1 ? t.state = 4 : t.state -= 1
    return
end

"""
    reset!(t::AbstractTetromino)

Resets a tetromino to it's starting position
"""
function reset!(t::AbstractTetromino)
    t.row, t.col, t.state = 2, 4, 1
    return
end

"""
The I_PIECE is a long straight bar.
This piece is the only piece capable of producing a tetris when dropped.
"""
Base.@kwdef mutable struct I_PIECE{T<:Integer} <: AbstractTetromino
    color::T = 1
    row::T = 2
    col::T = 4
    state::T = 1
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

"""
The J_PIECE is a 3-long straight bar with a block on it's left.
"""
Base.@kwdef mutable struct J_PIECE{T<:Integer} <: AbstractTetromino
    color::T = 2
    row::T = 2
    col::T = 4
    state::T = 1
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

"""
The L_PIECE is a 3-long straight bar with a block on it's right.
"""
Base.@kwdef mutable struct L_PIECE{T<:Integer} <: AbstractTetromino
    color::T = 3
    row::T = 2
    col::T = 4
    state::T = 1
    shapes::Vector{Matrix{T}} = [
        [0 0 3
         3 3 3
         0 0 0],
        
        [0 3 0
         0 3 0
         0 3 3],
        
        [0 0 0
         3 3 3
         3 0 0],
         
        [3 3 0
         0 3 0
         0 3 0],
    ]
end

"""
The O_PIECE is a square.
This piece is unique in the sense that it doesn't rotate
"""
Base.@kwdef mutable struct O_PIECE{T<:Integer} <: AbstractTetromino
    color::T = 4
    row::T = 2
    col::T = 4
    state::T = 1
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

"""
The S_PIECE is an offset stack of horizontal 2-blocks lines with it's top line
protruding to the right.
"""
Base.@kwdef mutable struct S_PIECE{T<:Integer} <: AbstractTetromino
    color::T = 5
    row::T = 2
    col::T = 4
    state::T = 1
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

"""
The T_PIECE is an inverted T.
"""
Base.@kwdef mutable struct T_PIECE{T<:Integer} <: AbstractTetromino
    color::T = 6
    row::T = 2
    col::T = 4
    state::T = 1
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

"""
The Z_PIECE is an offset stack of horizontal 2-blocks lines with it's top line
protruding to the left.
"""
Base.@kwdef mutable struct Z_PIECE{T<:Integer} <: AbstractTetromino
    color::T = 7
    row::T = 2
    col::T = 4
    state::T = 1
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

@enum COLORS begin
    BLACK = 0
    CYAN = 1
    BLUE = 2
    ORANGE = 3 
    YELLOW = 4
    GREEN = 5
    PURPLE = 6
    RED = 7
end
