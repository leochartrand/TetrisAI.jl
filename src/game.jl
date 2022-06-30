#init 
using TetrisAI

global game = TetrisGame()

WIDTH = 1000
HEIGHT = 1000

Paused = false
Timer = 0
Gravity = 48

# Sprites
bg = Actor("bg.png")
pause = Actor("pause.png")
I = Actor("i.png")
J = Actor("j.png")
L = Actor("l.png")
O = Actor("o.png")
S = Actor("s.png")
T = Actor("t.png")
Z = Actor("z.png")

gravityDict = Dict([(1,43), (2,38), (3,33), (4,28), (5,23), (6,18), (7,13), (8,8), (9,6), (10,5), (13,4), (16,3), (19,2), (29,1)])

tetrominoesDict = Dict([(0, 0), (1, I), (2, J), (3, L), (4, O), (5, S), (6, T), (7, Z)])

function softDrop()
    resetTimer()
end

function hardDrop()
    resetTimer()
end

function holdPiece()

end

function pauseGame()
    global Paused = !Paused
end

function quitGame()
    exit()
end

# Functions

function drawBoard(grid::TetrisAI.Game.AbstractGrid)

    let NB_ROWS = grid.rows,
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

function on_key_down(g::Game, k)
    global game
    if !Paused
        if (k == Keys.LEFT)
            TetrisAI.Game.move_left!(game)
        elseif (k == Keys.RIGHT)
            TetrisAI.Game.move_right!(game)
        elseif (k == Keys.UP || k == Keys.X)
            TetrisAI.Tetrominoes.rotate_right!(game)
        elseif (k == Keys.LCTRL || k == Keys.Z)
            TetrisAI.Tetrominoes.rotate_left!(game)
        elseif (k == Keys.DOWN)
            softDrop()
        elseif (k == Keys.SPACE)
            TetrisAI.Game.hard_drop_piece!(game)
            TetrisAI.Game.play_step!(game)
            resetTimer()
        elseif (k == Keys.LSHIFT || k == Keys.C)
            holdPiece()
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

function timeStep()
    global Timer, game
    Timer += 1
    if Timer >= Gravity
        TetrisAI.Game.play_step!(game)
        resetTimer()
    end
    return
end

function resetTimer()
    global Timer = 0
end

function levelUp()
    global Level += 1
    if Level in keys(gravityDict)
        global Gravity = gravityDict[Level]
    end
end

function draw(g::Game)
    global game
    draw(bg)
    drawBoard(game.grid)
    txt = TextActor(string(Timer), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    txt.pos = (0,0)
    draw(txt)
    lvl = TextActor(string(game.level), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    lvl.center = (875,425)
    draw(lvl)
    scr = TextActor(string(game.score), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    scr.center = (750,625)
    draw(scr)
    lnz = TextActor(string(game.line_count), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    lnz.center = (750,825)
    draw(lnz)
    if Paused
        draw(pause)
    end
end

function update(g::Game)
    if !Paused
        timeStep()
    end
end
