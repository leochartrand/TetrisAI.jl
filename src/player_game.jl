#init 
using TetrisAI

global game = TetrisGame()
global Paused = false
global input = :nothing

WIDTH = 1000
HEIGHT = 1000

# Sprites
background = Actor("bg.png")
pause_overlay = Actor("pause.png")
gameover_overlay = Actor("gameover.png")
I = Actor("i.png")
J = Actor("j.png")
L = Actor("l.png")
O = Actor("o.png")
S = Actor("s.png")
T = Actor("t.png")
Z = Actor("z.png")
I_preview = Actor("i_preview.png")
J_preview = Actor("j_preview.png")
L_preview = Actor("l_preview.png")
O_preview = Actor("o_preview.png")
S_preview = Actor("s_preview.png")
T_preview = Actor("t_preview.png")
Z_preview = Actor("z_preview.png")

global tetrominoesDict = Dict([(0, 0), (1, I), (2, J), (3, L), (4, O), (5, S), (6, T), (7, Z)])
global previewsDict = Dict([(0, 0), (1, I_preview), (2, J_preview), (3, L_preview), (4, O_preview), (5, S_preview), (6, T_preview), (7, Z_preview)])

"""
Checks for keyboard input.
"""
function on_key_down(g::Game, k)
    global game, Paused, input
    # Pause, debug and quit
    if k == Keys.P
        if game.is_over
            # Resets the game when game is over
            reset!(game)
            input = :nothing
        else
            # Pauses or unpauses the game
            Paused = !Paused
        end
    end
    if k == Keys.D
        # Debug print
        println(game)
    end
    if k == Keys.Q
        # Quits the game (exits the julia environment)
        exit()
    end
    # Tetris Input
    if !Paused
        if (k == Keys.LEFT)
            input = :move_left
        elseif (k == Keys.RIGHT)
            input = :move_right
        elseif (k == Keys.UP || k == Keys.X)
            input = :rotate_clockwise
        elseif (k == Keys.DOWN)
            input = :rotate_counter_clockwise
        elseif (k == Keys.SPACE)
            input = :hard_drop
        elseif (k == Keys.LSHIFT || k == Keys.C)
            input = :hold_piece
        end
    end
end

"""
Base GameZero.jl function, called every frame. Draws everything on screen.
"""
function draw(g::Game)
    global game, Paused
    
    draw(background)

    # Draw the game board on screen
    let grid = game.grid,
        NB_ROWS = grid.rows,
        NB_COLS = grid.cols,
        NB_VISIBLE_ROWS = 20,
        NB_HIDDEN_ROWS = NB_ROWS - NB_VISIBLE_ROWS

        for i in NB_HIDDEN_ROWS+1:NB_ROWS, j in 1:NB_COLS
            value = grid.cells[i,j]
            if value > 0
                square = tetrominoesDict[value]
                square.center = (40j + 30, 40i - 40)
                draw(square)
            end
        end
    end
    
    # Draw the 3 next pieces
    x = 625
    preview_pieces = get_preview_pieces(game.bag)
    for piece in preview_pieces
        preview = previewsDict[piece.color]
        preview.center = (x,225)
        draw(preview)
        x += 130
    end

    # Draw the held piece
    if !(game.hold_piece === nothing)
        piece = previewsDict[game.hold_piece.color]
        piece.center = (625, 425)
        draw(piece)
    end

    # Draw stats
    level = TextActor(string(game.level), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    level.center = (875,425)
    draw(level)
    score = TextActor(string(game.score), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    score.center = (750,625)
    draw(score)
    line_count = TextActor(string(game.line_count), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    line_count.center = (750,825)
    draw(line_count)

    # Draw overlays
    if Paused
        draw(pause_overlay)
    end
    if game.is_over
        draw(gameover_overlay)
    end
end

"""
Base GameZero.jl function, called every frame. Updates the game state.
"""
function update(g::Game)
    global game, Paused, input
    if !Paused && !game.is_over
        send_input!(game, input)
        tick!(game)
        # Reset input for next tick
        input = :nothing
        # Check for constant input for soft drop
        if g.keyboard.Z || g.keyboard.LCTRL 
            send_input!(game, :nothing)
            tick!(game)
        end
    end
end