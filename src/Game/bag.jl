Base.@kwdef mutable struct Bag{T<:Vector{<:AbstractTetromino}} <: AbstractBag
    pieces::T = AbstractTetromino[]
    previews::Int = 3
end