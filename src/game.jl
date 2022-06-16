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

board = fill(0,10,20)
board[1,20] = 1
board[1,19] = 1
board[1,18] = 1
board[1,17] = 1
board[2,20] = 6
board[3,20] = 6
board[4,20] = 6
board[3,19] = 6

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

end


# Functions
function getSquare(n)
    if n == 1
        return I
    elseif n == 2
        return J
    elseif n == 3
        return L
    elseif n == 4
        return O
    elseif n == 5
        return S
    elseif n == 6
        return T
    elseif n == 7
        return Z
    end    
end

function drawBoard()
    for i in 1:10, j in 1:20
        value = board[i,j]
        if value > 0
            square = getSquare(value)
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
    grvt = Gravity
    if Level == 1
        grvt = 43
    elseif Level == 2
        grvt = 38
    elseif Level == 3
        grvt = 33
    elseif Level == 4
        grvt = 28
    elseif Level == 5
        grvt = 23
    elseif Level == 6
        grvt = 18
    elseif Level == 7
        grvt = 13
    elseif Level == 8
        grvt = 8
    elseif Level == 9
        grvt = 6
    elseif Level == 10
        grvt = 5
    elseif Level == 13
        grvt = 4
    elseif Level == 16
        grvt = 3
    elseif Level == 19
        grvt = 2
    elseif Level == 29
        grvt = 1
    end
    global Gravity = grvt
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
