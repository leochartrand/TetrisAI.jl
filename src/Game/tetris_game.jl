
import ..Tetrominoes: rotate_left!, rotate_right!

"""
Representation of a tetris game
"""
Base.@kwdef mutable struct TetrisGame{T<:Integer} <: AbstractGame
    seed::T = 0
    is_over::Bool = false
    level::T = 1
    line_count::T = 0
    score::T = 0
    active_piece::AbstractTetromino = get_random_piece()
    hold_piece::Union{AbstractTetromino, Nothing} = nothing
    bag::Bag = Bag()
    grid::Grid = Grid()
end

function rotate_left!(game::AbstractGame)
    # Clear the space occupied by the active piece
    clear_piece_cells!(game)

    rotate_left!(game.active_piece)

    # Place the piece on the grid
    put_piece!(game)

    return
end


function rotate_right!(game::AbstractGame)

    # Clear the space occupied by the active piece
    clear_piece_cells!(game)

    rotate_right!(game.active_piece)

    # Place the piece on the grid
    put_piece!(game)

    return
end

function clear_piece_cells!(game::AbstractGame)
    let p = game.active_piece,
            x = p.x,
            y = p.y,
            nb_rows = size(p.shapes[p.idx], 1),
            nb_cols = size(p.shapes[p.idx], 2)

            # Clear the board at the current position of the piece
            game.grid.cells[x:x+nb_rows, y:y+nb_cols] .= 0
    end
    return
end

function put_piece!(game::AbstractGame)
    let p = game.active_piece,
        x = p.x,
        y = p.y,
        nb_rows = size(p.shapes[p.idx], 1), 
        nb_cols = size(p.shapes[p.idx], 2)

        # Place the piece on the grid
        for i in 1:nb_rows, j in 1:nb_cols
            game.grid.cells[x+i-1, y+j-1] = p.shapes[p.idx][i, j]
        end
    end

    return
end