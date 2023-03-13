using Statistics

"""
Returns the vertical index of the topmost occupied cell for each column.
"""
function get_column_heights(g::Matrix{Int})
    # Creates a copy of the grid
    column_heights = zeros(Int, 10)
    # Simplifies representation of occupied cells
    for j in 1:10
        for i in 1:20
            if g[i,j] > 0
                column_heights[j] = 20-j
                break
            end
        end
    end

    # Return number of holes
    return column_heights
end

"""
Bumpiness value function. 
Calculates the sum off differences in adjacent column heights.
"""
function get_bumpiness(g::Matrix{Int})
    
    column_heights = get_column_heights(g)

    value = 0.0

    for i in 1:9
        value += abs(column_heights[i] - column_heights[i+1])
    end

    # Returns bumpiness value
    return value
end

"""
Bumpiness value function.
Same function as above, but taking in the array of the heights or each column.
"""
function get_bumpiness(heights::AbstractArray{Int})
    bumpiness = 0
    nb_cols = size(heights, 1)
    for i in 1:nb_cols
        if i != nb_cols
            bumpiness += abs(heights[i] - heights[i + 1])
        end
    end

    return bumpiness
end


"""
Check if a given cell (tuple of cell indexes) is positioned in the visible grid
"""
function is_in_visible_grid(row, col)
    return (row >= 1 && row <= 20 && col >= 1 && col <= 10)
end

"""
Recursive method to flood adjacent cells with a given value
"""
function flood_cell(raw_grid::Matrix{Int}, feature_grid::Matrix{Int}, row, col, target, value)
    # Check if cell is in valid position and holds the target value
    if is_in_visible_grid(row, col) && raw_grid[row, col] == target && feature_grid[row, col] != value
        # Fill the cell the new value and spread
        feature_grid[row, col] = value
        check1 = flood_cell(raw_grid, feature_grid, row-1, col, target, value)
        check2 = flood_cell(raw_grid, feature_grid, row+1, col, target, value)
        check3 = flood_cell(raw_grid, feature_grid, row, col-1, target, value)
        check4 = flood_cell(raw_grid, feature_grid, row, col+1, target, value)
    end
    return true
end

"""
Returns the distance between the played piece and the height of the piece's colum.
"""
function get_fall_height(g::Matrix{Int}, active_piece_row::Int, active_piece_col::Int)
    column_heights = get_column_heights(g)
    if active_piece_col < 1
        active_piece_col = 1 
    end
    if active_piece_col > 10
        active_piece_col = 10
    end
    fall_height = Float64(24 - active_piece_row - column_heights[active_piece_col])
    return fall_height
end

"""
Returns the number of holes on the grid.
A cell is considered a hole if there is no path from the cell to 
the top of the grid and the cell is empty.
"""
function get_n_holes(feature_grid::Matrix{Int})
    # Holes are empty cells that see themselves filled in the opaque grid
    n_holes = 0.0
    for i in 1:20, j in 1:10
        if feature_grid[i,j] == 2 
            n_holes += 1.0
        end
    end

    # Return number of holes
    return n_holes
end

"""
Returns a grid that highlights the features of every cell
Features:
    0 = Empty;
    1 = Filled;
    2 = Ative Piece;
    3 = Hole;
    4 = Notch;
    5 = Crevasse
"""
function get_feature_grid(raw_grid::Matrix{Int})
    # Assume every block is filled
    feature_grid = ones(Int, 20, 10)
    # Find first empty cell in top row
    row = 1
    col = 0
    for i in 1:10
        if raw_grid[1,i] == 0
            col = i
            break
        end
    end

    # Flood the opaque grid from the top
    flooded = flood_cell(raw_grid, feature_grid, row, col, 0, 0)

    # Identify active piece cells and holes
    for i in 1:20, j in 1:10
        # Active Piece
        if raw_grid[i,j] == 2
            feature_grid[i,j] = 2
        end
        # Holes are empty cells that are filled in the opaque grid
        if raw_grid[i,j] == 0 && feature_grid[i,j] == 1
            feature_grid[i,j] = 3
        end
    end

    # Notches are empty cells that are roofed by filled cells in the same column
    for j in 1:10
        roofed = false
        for i in 1:20
            if roofed && feature_grid[i,j] == 0
                feature_grid[i,j] = 4
            end
            if !roofed && feature_grid[i,j] == 1
                roofed = true
            end
        end
    end

    # Crevasses are empty cells which can only be filled by an I piece.
    # Identify active piece cells and holes
    for i in 3:20, j in 1:10
        # Empty cell
        if feature_grid[i,j] == 0 && feature_grid[i-1,j] == 0 && feature_grid[i-2,j] == 0
            if (j==1 || feature_grid[i-1,j-1] == 1 && feature_grid[i-2,j-1] == 1) && (j==10 || feature_grid[i-1,j+1] == 1 && feature_grid[i-2,j+1] == 1)
                feature_grid[i,j] = 5
            end
        end
    end

    return feature_grid
end

"""
Util function to print colored cell.
Used by print_grids.
"""
function print_cell(value)
    if value == 0     # Empty
        printstyled("#", color = :normal)
    elseif value == 1 # Filled
        printstyled("#", color = :blue)
    elseif value == 2 # Active Piece
        printstyled("#", color = :yellow)
    elseif value == 3 # Hole
        printstyled("#", color = :red)
    elseif value == 4 # Notch
        printstyled("#", color = :green)
    else # value == 5 : Crevasse
        printstyled("#", color = :magenta)
    end
end

"""
Util function to print raw grid and feature grid side by side.
For feature engineering development.
"""
function print_grids(raw_grid,feature_grid)
    println("--------RAW GRID------------FEATURE GRID-----")
    for i in 1:20
        print("| ")
        for j in 1:10
            print_cell(raw_grid[i, j])
            print(" ")
        end
        print("| ")
        for j in 1:10
            print_cell(feature_grid[i, j])
            print(" ")
        end
        println("|")
    end
end

"""
Extracts features from the game state. 
This feature vector approximates state value and can be fed into a model.
"""
function get_state_features(state::Vector{Int}, active_piece_row::Int, active_piece_col::Int)
    
    # Feature vector
    features = Float64[]

    # Extract board state and reshape
    raw_grid = permutedims(reshape(state[59:258], (10,20)),(2,1))

    # Generate Feature grid
    feature_grid = get_feature_grid(raw_grid)
    
    column_heights = get_column_heights(feature_grid)
    for i in 1:10
        vcat(features,column_heights[i])
    end
    max_height = maximum(column_heights)
    vcat(features,max_height)
    mean_height = Statistics.mean(column_heights)
    vcat(features,mean_height)
    fall_height = get_fall_height(raw_grid, active_piece_row, active_piece_col)
    vcat(features,fall_height)
    bumpiness = get_bumpiness(raw_grid)
    vcat(features,bumpiness)
    n_holes = get_n_holes(raw_grid)
    vcat(features,n_holes)

    # print_grids(raw_grid,feature_grid)

    return features
end

"""
Shaping the reward based on human developped heuristics to guide the agent to its first line completed.
"""
function computeIntermediateReward!(game_grid::Matrix{Int}, last_score::Integer, lines::Int)
    height_cte = -0.510066
    lines_cte = 0.760666
    holes_cte = -0.35663
    bumpiness_cte = -0.184483

    feature_grid = get_feature_grid(game_grid) 

    heights = get_column_heights(game_grid)
    height_avg = mean(heights)
    bumps = get_bumpiness(heights)
    holes = get_n_holes(feature_grid)

    print("height_avg: ", height_avg, " bumps: ", bumps, " holes: ", holes, " lines: ", lines, "\n")

    score = (height_cte * height_avg) + (lines_cte * lines) + (holes_cte * holes) + (bumpiness_cte * bumps)
    reward = score - last_score
    last_score = Int(round(score))
    return reward
end