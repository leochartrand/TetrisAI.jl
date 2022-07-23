"""
Returns a random onehot vector of output_size. 
"""
function random_Net(output_size::Integer)
    # Ignore the state vector and returns a random output onehot vector 
    return _ -> setindex!(zeros(Int, output_size), 1, rand(1:output_size))
end

"""
Small neural net consisting of 2 linear layers.
"""
function linear_QNet(input_size::T, output_size::T) where {T<:Integer}
    
    let hidden_row_input = 756,
        hidden_row_output = 64
        
        # Creating the model
        model = Chain(
            # Linear layers
            Dense(input_size => hidden_row_input, relu),
            Dense(hidden_row_input => hidden_row_output, relu),
            Dense(hidden_row_output => output_size)
        )

        return model
    end
end
