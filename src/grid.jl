abstract type AbstractGrid end

Base.@kwdef mutable struct Grid{T<:Integer} <: AbstractGrid
    rows::T = 40
    cols::T = 10
    cells::Matrix{T} = zeros(Int, rows, cols)
end

function Base.show(io::IO, g::Grid)
    println("Rows: ", g.rows)
    println("Columns: ", g.cols)
    # Only showing visible rows
    for i = 21:40
        println(g.cells[i, :])
    end
end