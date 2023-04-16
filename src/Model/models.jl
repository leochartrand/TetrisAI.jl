"""
    random_Net(output_size::Integer)

Returns a random onehot vector of output_size. 
"""
function random_Net(output_size::Integer)
    # Ignore the state vector and returns a random output onehot vector 
    return _ -> setindex!(zeros(Int, output_size), 1, rand(1:output_size))
end

"""
    dense_net(
        input_size::T, 
        output_size::T, 
        hidden_size_1::T = 756, 
        hidden_size_2::T = 64) where {T<:Integer}

Small neural net consisting of 3 layers.
"""
function dense_net(
    input_size::T, 
    output_size::T, 
    hidden_size_1::T = 756, 
    hidden_size_2::T = 64) where {T<:Integer}
        
    # Creating the model
    model = Chain(
        # Layers
        Dense(input_size => hidden_size_1, relu),
        Dense(hidden_size_1 => hidden_size_2, relu),
        Dense(hidden_size_2 => output_size)
    ) |> f64

    return model
end
