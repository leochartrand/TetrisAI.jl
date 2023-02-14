using Statistics

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
    steps::T = 0
    new_hold::Bool = false
    hard_dropped::Bool = false
    gravity::T = 48
    gravitySteps::T = 0
    last_score::T = 0
end

global gravityDict = Dict([(0, 48), (1,43), (2,38), (3,33), (4,28), (5,23), (6,18), (7,13), (8,8), (9,6), (10,5), (11,5), (12,5), (13,4), (14,4), (15,4), (16,3), (17,3), (18,3), (19,2), (20,2), (21,2), (22,2), (23,2), (24,2), (25,2), (26,2), (27,2), (28,2), (29,1)])

"""
Function used to send inputs to the game. 

This is the only function of the tetris API that is available to the user. 
Every attempt to change the game's state should be sent through this function.
"""
function send_input!(game::AbstractGame, input::Union{AbstractArray{<:Integer}, Symbol})
    
    let VALID_INPUTS = [
        :nothing,   
        :move_left,
        :move_right,
        :hard_drop,
        :rotate_clockwise,
        :rotate_counter_clockwise,
        :hold_piece
        ]
        if typeof(input) <: AbstractArray{<:Integer}
            input = argmax(input)
            if 1 <= input <= length(VALID_INPUTS)
                f = Symbol(:input_, VALID_INPUTS[input], :!)
                getfield(@__MODULE__, f)(game)
            else
                error("Invalid input: $input\n\nInput must be between: [1, $(length(VALID_INPUTS))]")
            end
        elseif typeof(input) == Symbol
            if input in VALID_INPUTS
                f = Symbol(:input_, input, :!)
                getfield(@__MODULE__, f)(game)
            else
                error("Invalid input: $input\n\nInput must be in:\n$VALID_INPUTS")
            end
        end
    end
    return
end

function convert_input_to_vector(input::Symbol)
    action = zeros(Int, 7)
    if input == :nothing
        action[1] = 1
    elseif input == :move_left
        action[2] = 1
    elseif input == :move_right
        action[3] = 1
    elseif input == :hard_drop
        action[4] = 1
    elseif input == :rotate_clockwise
        action[5] = 1
    elseif input == :rotate_counter_clockwise
        action[6] = 1
    elseif input == :hold_piece
        action[7] = 1
    end
    return action
end

"""
Advance the game state by one state.
"""
function tick!(game::AbstractGame)

    reward = 0
    game.steps +=1
    game.gravitySteps += 1
    cte = 0 # 1 means we only reward based on the lines cleared

    if is_collision(game.grid, game.active_piece)
        
        # Check for game over collision at starting row
        if game.active_piece.row == 2
            reward = -100
            game.is_over = true
            return reward, game.is_over, game.score
        end

        # Freeze the piece in place and get a new piece
        if game.gravitySteps >= game.gravity || game.hard_dropped
            game.active_piece = pop_piece!(game.bag)
            game.new_hold = false
            game.hard_dropped = false
        end

        # Check if we have cleared lines only when piece is dropped
        lines = check_for_lines!(game)

        if lines != 0
            cte += 0.1
        end
        # Exploration to use an intermediate fitness function for early stages
        # Ref: http://cs231n.stanford.edu/reports/2016/pdfs/121_Report.pdf
        # As we score more and more lines, we change the scoring more and more to the
        # game's score instead of the intermediate rewards that are used only for the
        # early stages.
        reward += Int(round(((1 - cte) * computeIntermediateReward!(game, lines)) + (cte * (lines ^ 2))))

    elseif game.gravitySteps >= game.gravity
        game.gravitySteps = 0
        clear_piece_cells!(game.grid, game.active_piece)
        drop!(game.active_piece)
        # Draws the new piece on the grid
        put_piece!(game.grid, game.active_piece)
    end

    return reward, game.is_over, game.score
end

function computeIntermediateReward!(game::AbstractGame, lines::Int)
    height_cte = -0.510066
    lines_cte = 0.760666
    holes_cte = -0.35663
    bumpiness_cte = -0.184483

    height, bumps, holes = fitnessStats(game)

    print("height: ", height, " bumps: ", bumps, " holes: ", holes, " lines: ", lines, "\n")

    score = (height_cte * height) + (lines_cte * lines) + (holes_cte * holes) + (bumpiness_cte * bumps)
    reward = score - game.last_score
    game.last_score = Int(round(score))
    return reward
end

function fitnessStats(game::AbstractGame)
    board_state = get_state(game.grid, game.active_piece)
    rows = game.grid.rows
    cols = game.grid.cols
    heights = Int[]
    holes = 0

    # We parse the grid each column from top to the first occupied cell.
    # At the first occupied cell, we compute the height of that column.

    for c in 1:cols
        found_first = false

        for r in 1:rows
            cell = board_state[r, c]

            if cell == 1 # Cell is occupied
                if !found_first 
                    push!(heights, (rows - r + 1))
                end
                found_first = true
            elseif cell == 0 # Cell is not occupied
                if found_first
                    holes += 1
                end
            end

            if r == rows && cell == 0 && !found_first # If the column is empty
                push!(heights, 0)
            end
        end
    end

    return mean(heights), computeBumpiness(heights), holes
end

function computeBumpiness(heights::AbstractArray)
    bumpiness = 0
    nb_cols = size(heights, 1)
    for i in 1:nb_cols
        if i != nb_cols
            bumpiness += abs(heights[i] - heights[i + 1])
        end
    end

    return bumpiness
end

function get_state(game::AbstractGame)

    # Empty state before construction
    state = Int[]

    let nb_pieces = 7
        piece_vector = zeros(Int, nb_pieces)
        # Adding the holding piece
        if game.hold_piece !== nothing
            piece_vector[game.hold_piece.color] = 1
        end
        state = vcat(state, piece_vector)

        # Adding the preview pieces to the game state
        for piece in get_preview_pieces(game.bag)
            piece_vector = zeros(Int, nb_pieces)
            piece_vector[piece.color] = 1
            state = vcat(state, piece_vector)
        end
    end
    
    # Generating board state
    board_state = get_state(game.grid, game.active_piece)

    # Adding the game board to the state vector
    state = vcat(state, reshape(transpose(board_state), (:,)))

    # Making sure the vector is all int type
    return state
end

function reset!(game::AbstractGame)
    game.is_over = false
    game.level = 0
    game.line_count = 0
    game.score = 0
    game.bag = Bag()
    game.active_piece = pop_piece!(game.bag)
    game.hold_piece = nothing
    game.grid = put_piece!(Grid(), game.active_piece)
    game.steps = 0
    game.new_hold = false
    game.gravity = 48
    game.gravitySteps = 0
    return game
end

"""
Clear full lines on the grid and adjust the score accordingly.

T-spins and exotic scoring not supported yet.
"""
function check_for_lines!(game::AbstractGame)
    
    local cleared_lines = 0
    
    let NB_VISIBLE_ROWS = 20,
        NB_HIDDEN_ROWS = game.grid.rows - NB_VISIBLE_ROWS,
        SCORE_LIST = [100, 300, 500, 800]   # Scores from single to tetris

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
                # printstyled("CLEARED\n", color = :red)
            end
        end

        if cleared_lines != 0
            game.line_count += cleared_lines
            # Increase level every 10 lines
            if game.line_count >= game.level*10 + 10
                levelUp(game)
            end
            game.score += SCORE_LIST[cleared_lines] * (game.level + 1)
            # printstyled(game.score, color = :blue)
            # print("\n")
        end
    end
    return cleared_lines
end

"""
Sets gravity according to the game level (stops checking at level 30 and over).
"""
function levelUp(game::AbstractGame)
    game.level += 1
    if game.level < 30
        game.gravity = gravityDict[game.level]
    end
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
        if !is_collision(game.grid, tmp, direction=:In_place)
            # Update the active piece
            game.active_piece = tmp
        end
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

        if !is_collision(game.grid, tmp, direction=:In_place)
            # Update the active piece
            game.active_piece = tmp
        end
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
    
    game.hard_dropped = true
    return
end

function input_hold_piece!(game::AbstractGame)

    if game.new_hold == false

        game.new_hold = true

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
    end
    return
end

"""
Does nothing.
"""
function input_nothing!(game::AbstractGame) end