#init 

WIDTH = 1000
HEIGHT = 1000

Paused = false

Score = 0
Lines = 0
Timer = 0
Level = 0
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
pause = Actor("pause.png")

#scenrio for testing
board = fill(0,10,20)
board[1,20] = 1
board[1,19] = 1
board[1,18] = 1
board[1,17] = 1
board[2,20] = 6
board[3,20] = 6
board[4,20] = 6
board[3,19] = 6

gravityDict = Dict([(1,43), (2,38), (3,33), (4,28), (5,23), (6,18), (7,13), (8,8), (9,6), (10,5), (13,4), (16,3), (19,2), (29,1)])

tetrominoesDict = Dict([(0, 0), (1, I), (2, J), (3, L), (4, O), (5, S), (6, T), (7, Z)])

# Commands
function moveLeft()

end

function moveRight()

end

function rotateClockwise()

end

function rotateCounterclockwise()

end

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

function drawBoard()
    for i in 1:10, j in 1:20
        value = board[i,j]
        if value > 0
            square = tetrominoesDict[value]
            square.center = (40i + 30, 40j + 80)
            draw(square)
        end
    end
end

function on_key_down(g::Game, k)
    if !Paused
        if (k == Keys.LEFT)
            moveLeft()
            levelUp()
        elseif (k == Keys.RIGHT)
            moveRight()
        elseif (k == Keys.UP || k == Keys.X)
            rotateClockwise()
        elseif (k == Keys.LCTRL || k == Keys.Z)
            rotateCounterclockwise()
        elseif (k == Keys.DOWN)
            softDrop()
        elseif (k == Keys.SPACE)
            hardDrop()
        elseif (k == Keys.LSHIFT || k == Keys.C)
            holdPiece()
        end
    end
    if k == Keys.P
        pauseGame()
    elseif k == Keys.Q
        quitGame()
    end
end

function timeStep()
    global Timer += 1
    if Timer >= Gravity
        resetTimer()
    end
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
    draw(bg)
    drawBoard()
    txt = TextActor(string(Timer), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    txt.pos = (0,0)
    draw(txt)
    lvl = TextActor(string(Level), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    lvl.center = (875,425)
    draw(lvl)
    scr = TextActor(string(Score), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
    scr.center = (750,625)
    draw(scr)
    lnz = TextActor(string(Lines), "bold"; font_size = 50, color = Int[255, 255, 255, 255])
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
