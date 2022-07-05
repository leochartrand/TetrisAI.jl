#init 
using TetrisAI

global game = TetrisGame()

# Sprites
bg = Actor("bg.png")
pause = Actor("pause.png")
gameover = Actor("gameover.png")
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

WIDTH = 1000
HEIGHT = 1000

# Dict should be changed to map all levels or change the Gravity adjustments in timestep
gravityDict = Dict([(0, 48), (1,43), (2,38), (3,33), (4,28), (5,23), (6,18), (7,13), (8,8), (9,6), (10,5), (13,4), (16,3), (19,2), (29,1)])
tetrominoesDict = Dict([(0, 0), (1, I), (2, J), (3, L), (4, O), (5, S), (6, T), (7, Z)])
previewsDict = Dict([(0, 0), (1, I_preview), (2, J_preview), (3, L_preview), (4, O_preview), (5, S_preview), (6, T_preview), (7, Z_preview)])

"""
Sets gravity according to the game level.
"""
function levelUp()
    global Gravity
    let level = game.level
        while !(level in keys(gravityDict))
            level -= 1
        end
        Gravity = gravityDict[level]
    end
end

Paused = false
Timer = 0
Gravity = levelUp()

"""
Pauses or unpauses the game.
"""
function pauseGame()
    global Paused = !Paused
end

"""
Quits the game.
"""
function quitGame()
    exit()
end

"""
Draws the game board on screen.
"""
function drawBoard()
    global game
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
    return
end

"""
Draws the 3 next pieces.
"""
function drawNextPieces()
    global game
    x = 625
    preview_pieces = get_preview_pieces(game.bag)
    for piece in preview_pieces
        preview = previewsDict[piece.color]
        preview.center = (x,225)
        draw(preview)
        x += 130
    end
    return
end

"""
Draws the held piece.
"""
function drawHeldPiece()
    global game
    if !(game.hold_piece === nothing)
        piece = previewsDict[game.hold_piece.color]
        piece.center = (625, 425)
        draw(piece)
    end
end

"""
Checks for keyboard input.
"""
function on_key_down(g::Game, k)
    global game
    if game.is_over
        if k == Keys.P
            reset!(game)
        end
        return
    end
    if !Paused
        if (k == Keys.LEFT)
            send_input!(game, :move_left)
        elseif (k == Keys.RIGHT)
            send_input!(game, :move_right)
        elseif (k == Keys.UP || k == Keys.X)
            send_input!(game, :rotate_clockwise)
        elseif (k == Keys.DOWN)
            send_input!(game, :rotate_counter_clockwise)
        elseif (k == Keys.SPACE)
            send_input!(game, :hard_drop)
            resetTimer()
        elseif (k == Keys.LSHIFT || k == Keys.C)
            send_input!(game, :hold_piece)
        elseif (k == Keys.D)
            # Debug print
            println(game)
        end
    end
    if k == Keys.P
        pauseGame()
    elseif k == Keys.Q
        quitGame()
    end
end

"""
Increments the timer.
"""
function tick()
    global Timer, game, Gravity
    Timer += 1
    if Timer >= Gravity
        play_step!(game)
        levelUp()
        resetTimer()
    end
    return
end

"""
Resets the timer to 0.
"""
function resetTimer()
    global Timer = 0
end

"""
Base GameZero.jl function, called every frame. Draws everything on screen.
"""
function draw(g::Game)
    global game
    draw(bg)
    drawBoard()
    drawNextPieces()
    drawHeldPiece()

    # to remove
    # ticks = TextActor(string(Timer), "bold"; font_size = 50, color = Int[255, 255, 255, 255]) 
    # ticks.pos = (0,0)
    # draw(ticks)

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
    if Paused
        draw(pause)
    end
    if game.is_over
        draw(gameover)
    end
end

"""
Base GameZero.jl function, called every frame. Updates the game state.
"""
function update(g::Game)
    global game
    if !Paused && !game.is_over
        tick()
        # Check for constant input for soft drop
        if g.keyboard.Z || g.keyboard.LCTRL
            tick()
        end
    end
end
