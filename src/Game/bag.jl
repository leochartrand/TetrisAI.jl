Base.@kwdef mutable struct Bag <: AbstractBag
    bag_size::Int = 7
    previews::Int = 3
    pieces::Vector{<:AbstractTetromino} = AbstractTetromino[get_random_piece() for _ in 1:bag_size]
end

function Base.show(io::IO, b::AbstractBag)
    println("Bag size: $(b.bag_size)")
    println("Previews: $(b.previews)")
    println("Pieces\n------")
    for i in 1:b.bag_size
        println(b.pieces[i])
    end
end

function get_preview_pieces(b::AbstractBag)
    return b.pieces[1:b.previews]
end

function pop_piece!(b::AbstractBag)
    piece = popfirst!(b.pieces)
    push!(b.pieces, get_random_piece())
    return piece
end