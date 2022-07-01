
# import ..Tetrominoes: rotate_left!, rotate_right!, drop!, move_left!, move_right!
abstract type AbstractGame end
"""
Representation of a tetris game
"""
Base.@kwdef mutable struct TetrisGame{T<:Integer} <: AbstractGame
    seed::T = 0
    is_over::Bool = false
    level::T = 0
    line_count::T = 0
    score::T = 0
    bag::Bag = Bag()
    active_piece::Tetrominoes.AbstractTetromino = pop_piece!(bag)
    hold_piece::Union{Tetrominoes.AbstractTetromino,Nothing} = nothing
    grid::Grid = put_piece!(Grid(), active_piece)
end

"""
Function used to send inputs to the game. 

This is the only function of the tetris API that is available to the user. 
Every attempt to change the game's state should be sent through this function.
"""
function send_input!(game::AbstractGame, input::Symbol)
    
    let VALID_INPUTS = [      
        :move_left,
        :move_right,
        :soft_drop,
        :hard_drop,
        :rotate_clockwise,
        :rotate_counter_clockwise,
        :hold_piece
        ]
        if input in VALID_INPUTS
            f = Symbol(:input_, input, :!)
            getfield(@__MODULE__, f)(game)
        else
            error("Invalid input: $input\n\nInput must be in:\n$VALID_INPUTS")
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
            game.score += SCORE_LIST[cleared_lines] * (game.level + 1)
        end
    end
    return
end

"""
Rotates a piece counter-clockwise on the grid.

This function should be the one called from player interaction.
"""
function input_rotate_counter_clockwise!(game::AbstractGame)
    # Clear the space occupied by the active piece
    clear_piece_cells!(game.grid, game.active_piece)

    local tmp = deepcopy(game.active_piece)

    # Rotates the temp piece to validate it's in bounds
    rotate_counter_clockwise!(tmp)

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
function input_rotate_clockwise!(game::AbstractGame)

    # Clear the space occupied by the active piece
    clear_piece_cells!(game.grid, game.active_piece)

    local tmp = deepcopy(game.active_piece)

    # Rotates the temp piece to validate it's in bounds
    rotate_clockwise!(tmp)

    if !is_out_of_bounds(game.grid, tmp)
        # Update the active piece
        game.active_piece = tmp
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)

    return
end

function input_move_left!(game::AbstractGame)
    clear_piece_cells!(game.grid, game.active_piece)

    local tmp = deepcopy(game.active_piece)

    # Rotates the temp piece to validate it's in bounds
    move_left!(tmp)

    # Check wheter the piece will be out of bound
    if !is_out_of_bounds(game.grid, tmp)
        
        # Piece is in bounds, check for collision
        if !is_collision(game.grid, game.active_piece, direction=:Left)
            # Update the active piece
            game.active_piece = tmp
        end
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)
end

function input_move_right!(game::AbstractGame)
    clear_piece_cells!(game.grid, game.active_piece)

    local tmp = deepcopy(game.active_piece)

    # Rotates the temp piece to validate it's in bounds
    move_right!(tmp)

    if !is_out_of_bounds(game.grid, tmp)
        # Piece is in bounds, check for collision
        if !is_collision(game.grid, game.active_piece, direction=:Right)
            # Update the active piece
            game.active_piece = tmp
        end
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)
end

function input_hard_drop!(game::AbstractGame)

    # Clear the space occupied by the active piece
    clear_piece_cells!(game.grid, game.active_piece)

    # Drop the piece until we reach a collision state
    while (!is_collision(game.grid, game.active_piece))
        drop!(game.active_piece)
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)
    play_step!(game)
    return
end

function input_hold_piece!(game::AbstractGame)

    # Clear the space occupied by the active piece
    clear_piece_cells!(game.grid, game.active_piece)

    if game.hold_piece === nothing
        # Place the active piece in the hold
        game.hold_piece = game.active_piece
        # Get a new piece
        game.active_piece = pop_piece!(game.bag)
    else
        # Swaps the pieces
        game.active_piece, game.hold_piece = game.hold_piece, game.active_piece
        reset!(game.active_piece)
    end

    # Place the piece on the grid
    put_piece!(game.grid, game.active_piece)
    return
end
