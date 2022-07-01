abstract type AbstractGrid end
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

function clear!(g::AbstractGrid)
    g.cells = zeros(Int, g.rows, g.cols)
    return
end

"""
Shifts the grid down above the specified row.
The grid doesn't implement gravity and acts as a sticky board by default.
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

"""
Puts a piece on the grid
"""
function put_piece!(g::AbstractGrid, t::Tetrominoes.AbstractTetromino)
    # Place the piece on the grid
    for i in 1:size(t, 1), j in 1:size(t, 2)
        if t[i, j] == t.color
            g.cells[t.row+i-1, t.col+j-1] = t[i, j]
        end
    end
    return g
end


"""
Clear the space occupied by the active piece in the grid

If the active piece overlap with other pieces in the grid, the other pieces will
not be cleared.
"""
function clear_piece_cells!(g::AbstractGrid, t::Tetrominoes.AbstractTetromino)
    # Place the piece on the grid
    for i in 1:size(t, 1), j in 1:size(t, 2)
        if t[i, j] == t.color
            g.cells[t.row+i-1, t.col+j-1] = 0
        end
    end
    return
end

"""
Check if a tetromino is out of bounds. Useful when performing moves and rotations.

Some parts of the tetromino shape can be out of bounds (0 in shape matrix),
we only perform OTB calculations on the actual blocks of the tetromino.
"""
function is_out_of_bounds(g::AbstractGrid, t::Tetrominoes.AbstractTetromino)
    # Iterate over every block of the tetromino matrix
    for i in 1:size(t, 1), j in 1:size(t, 2)
        # Calculate if a block of the tetromino is out of bounds
        if t[i, j] == t.color
            # Check for x/y coordinates
            if !(1 <= t.row + i - 1 <= g.rows) || !(1 <= t.col + j - 1 <= g.cols)
                return true
            end
        end
    end
    # Every block is in bounds
    return false
end

"""
Check if a tetromino will collide with another tetromino on the grid
"""
function is_collision(g::AbstractGrid, t::Tetrominoes.AbstractTetromino)
    # Iterate over every block of the tetromino matrix
    for i in 1:size(t, 1), j in 1:size(t, 2)
        # Calculate if a block will be on top of another tetromino
        if t[i, j] == t.color
            # Check if we are at the final row
            if t.row + i - 1 == g.rows
                return true
            end
        
            # There's a block below, we check if it's part of the same tetromino
            if g.cells[t.row+i, t.col+j-1] != 0                 
                # Collision because it's part of another tetromino
                if i == size(t, 1) || t[i+1, j] == 0
                    return true
                end
            end
        end
    end
    # Every block is in bounds
    return false
end

# function is_at_bottom(g::AbstractGrid, t::Tetrominoes.AbstractTetromino)
#     let nb_rows = size(t.shapes[t.idx], 1),
#         nb_cols = size(t.shapes[t.idx], 2)

#         # Iterate over every block of the tetromino matrix
#         for i in 1:nb_rows, j in 1:nb_cols
#             # Calculate if a block will be on top of another tetromino
#             if t.shapes[t.idx][i, j] == t.id
#                 # Check for other tetromino
#                 if t.x + i - 1 == g.rows
#                     return true
#                 end
#             end
#         end
#     end
#     # Every block is not at the bottom of the grid
#     return false
# end

# function check_condition(cond::Symbol, g::AbstractGrid, t::Tetrominoes.AbstractTetromino)

#     local CONDITIONS = Dict{Symbol, Expr}(
#         :OTB => :((!(1 <= t.x + i <= g.rows) || !(1 <= t.y + j <= g.cols)) && return true),
#         :COLLISION => :(grid.cells[t.x, t.y] != 0 && return true),
#         :BOTTOM => :((t.x + i) - 1 == g.rows && return true)
#     )

#     let nb_rows = size(t.shapes[t.idx], 1),
#         nb_cols = size(t.shapes[t.idx], 2)

#         # Iterate over every block of the tetromino matrix
#         for i in 1:nb_rows, j in 1:nb_cols
#             # Calculate if a block will be on top of another tetromino
#             if t.shapes[t.idx][i, j] == t.id
#                 # Check for other tetromino
#                 if t.x + i - 1 == g.rows
#                     return true
#                 end
#             end
#         end
#     end
#     # Every block is not at the bottom of the grid
#     return false
# end