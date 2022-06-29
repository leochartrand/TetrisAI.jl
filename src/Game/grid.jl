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

"""
Shifts the grid down above the specified row
"""
function downshift!(g::Grid, row::Int)
    # Shifts everything down in the grid
    for i in row:-1:2
        next_row = g.cells[i-1, :]
        # Replacing the current row with the one above
        g.cells[i, :] .= next_row
    end
    # Filling the top row with 0s
    g.cells[1, :] .= 0
    return
end


function put_piece!(t::AbstractTetromino, g::AbstractGrid)
    let x = t.x,
        y = t.y,
        nb_rows = size(t.shapes[t.idx], 1),
        nb_cols = size(t.shapes[t.idx], 2)

        # Place the piece on the grid
        for i in 1:nb_rows, j in 1:nb_cols
            g.cells[x+i-1, y+j-1] = t.shapes[t.idx][i, j]
        end
    end

    return g
end
