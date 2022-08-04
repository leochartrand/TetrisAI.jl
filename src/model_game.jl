#init 
using TetrisAI

global game = TetrisGame()
global game_over = false
global Paused = false
global stepTimer = 0
global const attentionSpan = 4
global attentionTimer = 0

global model_name = ""

open(joinpath(MODELS_PATH, "current_model"), "r") do file
    global model_name = readline(file)
    print(model_name)
end

global agent = load_agent(model_name)

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
global gravityDict = Dict([(0, 48), (1,43), (2,38), (3,33), (4,28), (5,23), (6,18), (7,13), (8,8), (9,6), (10,5), (11,5), (12,5), (13,4), (14,4), (15,4), (16,3), (17,3), (18,3), (19,2), (20,2), (21,2), (22,2), (23,2), (24,2), (25,2), (26,2), (27,2), (28,2), (29,1)])

"""
Sets gravity according to the game level (stops checking at level 30 and over).
"""
function levelUp()
    if game.level < 30
        global Gravity = gravityDict[game.level]
    end
end

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
Checks for keyboard input.
"""
function on_key_down(g::Game, k)
    global game, game_over
    if k == Keys.P
        if game_over
            reset!(game)
            game_over = false
        else
            pauseGame()
        end
    end
    if k == Keys.Q
        quitGame()
    end
end

"""
Increments the timer.
"""
function tick()
    global stepTimer, game, Gravity, game_over, attentionTimer, attentionSpan

    attentionTimer += 1
    if attentionTimer >= attentionSpan
        play_move()
        resetAttentionTimer()
    end

    stepTimer += 1
    if stepTimer >= Gravity
        _, game_over, _, _  = play_step!(game)
        levelUp()
        resetStepTimer()
    end
    return
end

"""
Gets the agent to play a move
"""
function play_move()
    global game, agent

    # Get the current step
    old_state = TetrisAI.Game.get_state(game)

    # Get the predicted move for the state
    move = TetrisAI.Agent.get_action(agent, old_state)
    TetrisAI.Game.send_input!(game, move)
end

"""
Resets the step timer.
"""
function resetStepTimer()
    global stepTimer = 0
end

"""
Resets the attention timer.
"""
function resetAttentionTimer()
    global attentionTimer = 0
end

"""
Base GameZero.jl function, called every frame. Draws everything on screen.
"""
function draw(g::Game)
    global game, Paused, game_over
    
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
    if game_over
        draw(gameover_overlay)
    end
end

"""
Base GameZero.jl function, called every frame. Updates the game state.
"""
function update(g::Game)
    global game, game_over
    if !Paused && !game_over
        tick()
        # Check for constant input for soft drop
        if g.keyboard.Z || g.keyboard.LCTRL
            tick()
        end
    end
end
