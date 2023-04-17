"""
Returns a random onehot vector of output_size. 
"""
function random_Net(output_size::T=7) where {T<:Integer}
    # Ignore the state vector and returns a random output onehot vector 
    return _ -> setindex!(zeros(Int, output_size), 1, rand(1:output_size))
end

"""
Small neural net consisting of 3 layers.
"""
function dense_net(input_size::T, output_size::T=7, hidden_size_1::T = 756, hidden_size_2::T = 64) where {T<:Integer}
        
    # Creating the model
    model = Chain(
        # Layers
        Dense(input_size => hidden_size_1, relu),
        Dense(hidden_size_1 => hidden_size_2, relu),
        Dense(hidden_size_2 => output_size)
    ) |> f64

    return model
end

"""
Convolutional Neural Net.

Input must be stored in WHCN order.
"""
function conv_net(output_size::T=7) where {T<:Integer}

    model = Chain(
        Conv((3, 3), 5 => 16, pad=(1, 1), relu),
        BatchNorm(16),
        Conv((3, 3), 16 => 32, pad=(0, 0), relu),
        BatchNorm(32),
        Conv((3, 3), 32 => 64, pad=(0, 0), relu),
        BatchNorm(64),
        flatten,
        Dense((64*6*16) => 64),
        relu,
        Dropout(0.5),
        Dense(64 => 7)
    ) |> f64

    return model
end

"""
Shared layers between the Policy and the Value Networks for PPOAgent.
"""
function ppo_shared_layers(obs_size::T, output_size::T = 512) {T<:Integer}
    model = Chain(
        Dense(obs_size => 256, relu),
        Dense(256 => 512, relu),
        Dense(512, output_size, relu)
    ) |> f64

    return model
end

"""
Policy Network for PPOAgent.
    It can take the output of the shared layers as well as the observation itself.
    We will need to apply softmax to get a probability of the outputs.
"""
function policy_ppo_net(input_size::T, output_size::T, hidden_size_1::T = 256, hidden_size_2::T = 128) where {T<:Integer}

    model = Chain(
        Dense(input_size => hidden_size_1, relu),
        Dense(hidden_size_1 => hidden_size_2, relu),
        Dense(hidden_size_2 => output_size)
    ) |> f64;

    return model
end

"""
Value Network for PPOAgent
    It can take the output of the shared layers as well as the observation itself.
"""
function value_ppo_net(input_size::T, hidden_size_1::T = 256, hidden_size_2::T = 128) where {T<:Integer}
    model = Chain(
        Dense(input_size => hidden_size_1, relu),
        Dense(hidden_size_1 => hidden_size_2, relu),
        Dense(hidden_size_2 => 1)
    ) |> f64;

    return model;
end
