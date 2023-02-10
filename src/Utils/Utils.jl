module Utils

export MODELS_PATH, message, set_message, upload_data, game_over, set_game, data_list, process_data, download_data

include("config.jl")

include("awss3.jl")

end # module