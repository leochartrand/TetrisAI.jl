module Moves

export move_left!, move_right!, drop!, rotate_clockwise!, rotate_counter_clockwise!

# Generic definitions for the moves interface
# -------------------------------------------
function move_left! end
function move_right! end
function drop! end
function rotate_clockwise! end
function rotate_counter_clockwise! end

end # module