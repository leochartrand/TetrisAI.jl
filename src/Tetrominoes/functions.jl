function rotate_left!(t::AbstractTetromino)
    t.idx == 1 ? t.idx = 4 : t.idx -= 1
    return
end

"""
Rotates the piece clockwise
"""
function rotate_right!(t::AbstractTetromino) 
    t.idx == 4 ? t.idx = 1 : t.idx += 1
    return
end
