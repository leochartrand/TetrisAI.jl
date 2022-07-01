#init 
using TetrisAI

global game = TetrisGame()

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

WIDTH = 1000
HEIGHT = 1000

# Dict should be changed to map all levels or change the Gravity adjustments in timestep
gravityDict = Dict([(0, 48), (1,43), (2,38), (3,33), (4,28), (5,23), (6,18), (7,13), (8,8), (9,6), (10,5), (13,4), (16,3), (19,2), (29,1)])
tetrominoesDict = Dict([(0, 0), (1, I), (2, J), (3, L), (4, O), (5, S), (6, T), (7, Z)])

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
            send_input!(game, :move_left)
        elseif (k == Keys.RIGHT)
            send_input!(game, :move_right)
        elseif (k == Keys.UP || k == Keys.X)
            send_input!(game, :rotate_clockwise)
        elseif (k == Keys.LCTRL || k == Keys.Z)
            # send_input!(game, :soft_drop)
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

function timeStep()
    global Timer, game, Gravity
    Timer += 1
    if Timer >= Gravity
        if play_step!(game)
            reset!(game)
        end
        levelUp()
        resetTimer()
    end
    return
end

function resetTimer()
    global Timer = 0
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
