"""
Returns a random onehot vector of output_size. 
"""
function random_Net(output_size::Integer)
    # Ignore the state vector and returns a random output onehot vector 
    return _ -> setindex!(zeros(Int, output_size), 1, rand(1:output_size))
end

"""
Small neural net consisting of 3 linear layers.
"""
function dense_net(input_size::T, hidden_size_1::T = 756, hidden_size_2::T = 64, output_size::T) where {T<:Integer}
        
    # Creating the model
    model = Chain(
        # Linear layers
        Dense(input_size => hidden_size_1, relu),
        Dense(hidden_size_1 => hidden_size_2, relu),
        Dense(hidden_size_2 => output_size)
    )

    return model
end
