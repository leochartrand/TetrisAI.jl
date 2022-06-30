
import ..Tetrominoes: rotate_left!, rotate_right!, drop!, move_left!, move_right!

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
    hold_piece::Union{AbstractTetromino,Nothing} = nothing
    grid::Grid = put_piece!(Grid(), active_piece)
end


"""
Clear full lines on the grid and adjust the score accordingly.

T-spins and exotic scoring not supported yet.
"""
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


"""
Advance the game state by one state.
"""
function play_step!(game::AbstractGame)

    if is_collision(game.grid, game.active_piece)
        # Freeze the piece in place and get a new piece
        game.active_piece = pop_piece!(game.bag)

        # Check if we have cleared lines only when piece is dropped
        check_for_lines!(game)
    else
        println("No colision")
        println(game.active_piece)
        clear_piece_cells!(game.grid, game.active_piece)
        println(game.grid)
        drop!(game.active_piece)
        println(game.active_piece)

        # Draws the new piece on the grid
        put_piece!(game.grid, game.active_piece)
    end
    return
end



"""
Rotates a piece counter-clockwise on the grid.

This function should be the one called from player interaction.
"""
function rotate_left!(game::AbstractGame)
    # Clear the space occupied by the active piece
    clear_piece_cells!(game.grid, game.active_piece)

    local tmp = deepcopy(game.active_piece)

    # Rotates the temp piece to validate it's in bounds
    rotate_left!(tmp)

    if !is_out_of_bounds(game.grid, tmp)
        # Update the active piece
        game.active_piece = tmp
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)

    return
end

"""
Rotates a piece clockwise on the grid.

This function should be the one called from player interaction.
"""
function rotate_right!(game::AbstractGame)

    # Clear the space occupied by the active piece
    clear_piece_cells!(game.grid, game.active_piece)

    local tmp = deepcopy(game.active_piece)

    # Rotates the temp piece to validate it's in bounds
    rotate_right!(tmp)

    if !is_out_of_bounds(game.grid, tmp)
        # Update the active piece
        game.active_piece = tmp
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)

    return
end

function move_left!(game::AbstractGame)
    clear_piece_cells!(game.grid, game.active_piece)

    local tmp = deepcopy(game.active_piece)

    # Rotates the temp piece to validate it's in bounds
    move_left!(tmp)

    if !is_out_of_bounds(game.grid, tmp)
        # Update the active piece
        game.active_piece = tmp
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)
end

function move_right!(game::AbstractGame)
    clear_piece_cells!(game.grid, game.active_piece)

    local tmp = deepcopy(game.active_piece)

    # Rotates the temp piece to validate it's in bounds
    move_right!(tmp)

    if !is_out_of_bounds(game.grid, tmp)
        # Update the active piece
        game.active_piece = tmp
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)
end

function hard_drop_piece!(game::AbstractGame)

    # Clear the space occupied by the active piece
    clear_piece_cells!(game.grid, game.active_piece)

    # Drop the piece until we reach a collision state
    while (!is_collision(game.grid, game.active_piece))
        drop!(game.active_piece)
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)
    return
end