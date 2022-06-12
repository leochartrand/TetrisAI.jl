function rotate_left!(t::AbstractTetromino) 
    @error "Not yet implemented."
end

function rotate_right!(t::AbstractTetromino) 
    @error "Not yet implemented."
end

function drop!(t::AbstractTetromino)
    for b in t.Coords
        b.y -= BLOCK_SIZE
    end
end

function move_left!(t::AbstractTetromino)
    for b in t.Coords
        b.x -= BLOCK_SIZE
        b.y -= BLOCK_SIZE
    end
end

function move_right!(t::AbstractTetromino)
    for b in t.Coords
        b.x += BLOCK_SIZE
        b.y += BLOCK_SIZE
    end
end