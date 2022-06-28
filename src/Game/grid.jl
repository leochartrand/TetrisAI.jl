Base.@kwdef mutable struct Grid{T<:Integer} <: AbstractGrid
    rows::T = 23
    cols::T = 10
    cells::Matrix{T} = zeros(Int, rows, cols)
end

function Base.show(io::IO, g::Grid)
    let NB_VISIBLE_ROWS = 20, NB_HIDDEN_ROWS = g.rows - NB_VISIBLE_ROWS

        println("Rows: ", g.rows)
        println("Columns: ", g.cols)

        # Showing board cells
        println("Hidden rows\n-----------")
        for i in 1:NB_HIDDEN_ROWS
            println(g.cells[i, :])
        end
        println("Visible rows\n------------")
        for i in NB_HIDDEN_ROWS+1:g.rows
            println(g.cells[i, :])
        end
    end
end