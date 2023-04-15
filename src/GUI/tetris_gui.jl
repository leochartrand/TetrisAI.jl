abstract type AbstractUI end

Base.@kwdef mutable struct TetrisUI <: AbstractUI
    # Sprites
    background::Actor = Actor("bg.png")
    splash::Actor = Actor("splash.png")
    pause_overlay::Actor = Actor("pause.png")
    gameover_overlay::Actor = Actor("gameover.png")
    I::Actor = Actor("i.png")
    J::Actor = Actor("j.png")
    L::Actor = Actor("l.png")
    O::Actor = Actor("o.png")
    S::Actor = Actor("s.png")
    T::Actor = Actor("t.png")
    Z::Actor = Actor("z.png")
    I_preview::Actor = Actor("i_preview.png")
    J_preview::Actor = Actor("j_preview.png")
    L_preview::Actor = Actor("l_preview.png")
    O_preview::Actor = Actor("o_preview.png")
    S_preview::Actor = Actor("s_preview.png")
    T_preview::Actor = Actor("t_preview.png")
    Z_preview::Actor = Actor("z_preview.png")
    # Dicts
    tetrominoesDict::Dict{Int, Union{Int, Actor}} = Dict([(0, 0), (1, I), (2, J), (3, L), (4, O), (5, S), (6, T), (7, Z)])
    previewsDict::Dict{Int, Union{Int, Actor}} = Dict([(0, 0), (1, I_preview), (2, J_preview), (3, L_preview), (4, O_preview), (5, S_preview), (6, T_preview), (7, Z_preview)])
    # Show splash screen on first frame
    is_first_frame::Bool = true
end

"""
    drawUI(GUI::TetrisUI, game::TetrisAI.Game.AbstractGame, Paused::Bool)

Render UI for Tetris' play
"""
function drawUI(GUI::TetrisUI, game::TetrisAI.Game.AbstractGame, Paused::Bool)

    if GUI.is_first_frame
        GameZero.draw(GUI.splash)
        GUI.is_first_frame = false
        return
    end

    GameZero.draw(GUI.background)

    # Draw the game board on screen
    let grid = game.grid,
        NB_ROWS = grid.rows,
        NB_COLS = grid.cols,
        NB_VISIBLE_ROWS = 20,
        NB_HIDDEN_ROWS = NB_ROWS - NB_VISIBLE_ROWS

        for i in NB_HIDDEN_ROWS+1:NB_ROWS, j in 1:NB_COLS
            value = grid.cells[i,j]
            if value > 0
                square = GUI.tetrominoesDict[value]
                square.center = (40j + 30, 40i - 40)
                GameZero.draw(square)
            end
        end
    end
    
    # Draw the 3 next pieces
    x = 625
    preview_pieces = TetrisAI.Game.get_preview_pieces(game.bag)
    for piece in preview_pieces
        preview = GUI.previewsDict[piece.color]
        preview.center = (x,225)
        GameZero.draw(preview)
        x += 130
    end

    # Draw the held piece
    if !(game.hold_piece === nothing)
        piece = GUI.previewsDict[game.hold_piece.color]
        piece.center = (625, 425)
        GameZero.draw(piece)
    end

    # Draw stats
    level = TextActor(string(game.level), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    level.center = (875,425)
    GameZero.draw(level)
    score = TextActor(string(game.score), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    score.center = (750,625)
    GameZero.draw(score)
    line_count = TextActor(string(game.line_count), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    line_count.center = (750,825)
    GameZero.draw(line_count)

    # Draw overlays
    if Paused
        GameZero.draw(GUI.pause_overlay)
    end
    if game.is_over
        GameZero.draw(GUI.gameover_overlay)
    end
end
