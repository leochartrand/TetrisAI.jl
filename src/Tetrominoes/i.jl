"""
The I_PIECE is a long straight bar.
This piece is the only piece capable of producing a tetris when dropped.
"""
Base.@kwdef mutable struct I_PIECE{T<:Integer} <: AbstractTetromino
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

function Base.show(io::IO, p::I_PIECE)
    println("Piece type: I_PIECE")
    println("Color: Cyan")
    println("Index: ", p.idx)
    for i = 1:4
        println(p.shapes[p.idx][i, :])
    end
end
