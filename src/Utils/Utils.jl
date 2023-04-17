module Utils

export DATA_PATH, MODELS_PATH, STATES_PATH, LABELS_PATH, SCOREBOARD_PATH, game_over, set_game, data_list, process_data, download_data

include("config.jl")

include("awss3.jl")

end # module