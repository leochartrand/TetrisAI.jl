abstract type AbstractBlock end

"""
A block of that forces you to have coordinates matching a preset BLOCK_SIZE

BLOCK_SIZE defaults to 20.
"""
mutable struct Block{T} <: AbstractBlock
    x::T
    y::T

    function Block(x::T, y::T) where T<:Integer
        @assert x % BLOCK_SIZE == 0 "X coordinate must be a multiple of $BLOCK_SIZE"
        @assert y % BLOCK_SIZE == 0 "Y coordinate must be a multiple of $BLOCK_SIZE"

        return new{T}(x, y)
    end
end

function Base.show(io::IO, b::Block)
    print("(x=", b.x, ", y=", b.y, ")")
end

function Base.:(==)(b1::Block, b2::Block)
    return b1.x == b2.x && b1.y == b2.y
end