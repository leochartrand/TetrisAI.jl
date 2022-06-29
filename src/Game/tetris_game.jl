
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
    bag::Bag = Bag()
    active_piece::AbstractTetromino = pop_piece!(bag)
    hold_piece::Union{AbstractTetromino, Nothing} = nothing
    grid::Grid = put_piece!(active_piece, Grid())
end

function rotate_left!(game::AbstractGame)
    # Clear the space occupied by the active piece
    clear_piece_cells!(game)

    rotate_left!(game.active_piece)

    # Place the piece on the grid
    put_piece!(game.active_piece, game.grid)

    return
end


function rotate_right!(game::AbstractGame)

    # Clear the space occupied by the active piece
    clear_piece_cells!(game)

    rotate_right!(game.active_piece)

    # Place the piece on the grid
    put_piece!(game.active_piece, game.grid)

    return
end

"""
Clear the space occupied by the active piece in the grid

If the active piece overlap with other pieces in the grid, the other pieces will
not be cleared.
"""
function clear_piece_cells!(game::AbstractGame)
    let p = game.active_piece,
        x = p.x,
        y = p.y,
        nb_rows = size(p.shapes[p.idx], 1),
        nb_cols = size(p.shapes[p.idx], 2),
        board = game.grid.cells

        # Clear the board at the current position of the piece
        [board[x, y] = 0 for x in x:x+nb_rows, y in y:y+nb_cols if board[x, y] == p.id]
    end
    return
end


function check_for_lines!(game::AbstractGame)
    let NB_VISIBLE_ROWS = 20,
        NB_HIDDEN_ROWS = game.grid.rows - NB_VISIBLE_ROWS,
        SCORE_LIST = [100, 300, 500, 800]   # Scores from single to tetris

        local cleared_lines = 0

        # We ignore the hidden rows when looking for lines
        for row in NB_HIDDEN_ROWS+1:game.grid.rows
            local is_full = true
            for col in 1:game.grid.cols
                if game.grid.cells[row, col] == 0
                    is_full = false
                    break
                end
            end

            # Every block in the row is occupied, whe delete
            if is_full
                game.grid.cells[row, :] .= 0
                cleared_lines += 1
                downshift!(game.grid, row)
            end
        end

        if cleared_lines != 0
            game.score += SCORE_LIST[cleared_lines] * game.level
        end
    end
    return
end
