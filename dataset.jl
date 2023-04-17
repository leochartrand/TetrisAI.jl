using JSON
using Random
using Statistics
using Printf
using ArgParse
using Base.Iterators

const DEFAULT_DATASET_SIZE = 50
const DEFAULT_HOLD_TOLERENCE = 0.035
const DEFAULT_OUTPUT_FILE = "dataset.json"
const DEFAULT_SEED = 0

const DATA_PATH = "data/"
const STATES_PATH = joinpath(DATA_PATH, "states")
const LABELS_PATH = joinpath(DATA_PATH, "labels")
const SCOREBOARD_PATH = joinpath(DATA_PATH, "scoreboard")


function collect_data()
    states_files = [joinpath(STATES_PATH, file) for file in readdir(STATES_PATH) if !startswith(file, ".")]
    labels_files = [joinpath(LABELS_PATH, file) for file in readdir(LABELS_PATH) if !startswith(file, ".")]

    sort!(states_files)
    sort!(labels_files)

    states = Vector{Vector{Dict{String,Vector{Int64}}}}()
    labels = Vector{Vector{Dict{String,Int64}}}()

    for sf in states_files
        _states = JSON.parse(readline(sf), dicttype=Dict{String,Vector{Int64}})
        push!(states, _states)
    end

    for lf in labels_files
        _labels = JSON.parse(readline(lf), dicttype=Dict{String,Int64})
        push!(labels, _labels)
    end

    lines = readlines(SCOREBOARD_PATH)

    scores = Vector{Int64}()
    for line in lines
        score = parse(Int, split(strip(line), ":")[2])
        push!(scores, score)
    end

    return states, labels, scores
end


function write_scoreboard(scoreboard::Vector{Tuple{String,Int}}, filename::String)
    open(filename, "w") do f
        for (game_id, score) in scoreboard
            write(f, "$(game_id) : $(score)\n")
        end
    end
end


function sort_games(states::Vector{Vector{Dict{String,Vector{Int64}}}}, labels::Vector{Vector{Dict{String,Int64}}}, scores::Vector{Int64}, reverse::Bool=false)

    indexes = sortperm(scores, rev=reverse)

    states = states[indexes]
    labels = labels[indexes]
    scores = scores[indexes]

    return states, labels, scores
end


function get_label_stats_for_game(game_labels::Vector{Dict{String,Int64}})
    stats = Dict{Int,Float64}()
    N = 0.
    for i in 2:7
        stats[i] = 0.
    end
    for label in game_labels
        stats[first(values(label))] += 1.
        N += 1.
    end
    for key in keys(stats)
        stats[key] /= N
    end

    return stats
end


function clean_games(states_lists::Vector{Vector{Dict{String,Vector{Int64}}}}, labels_lists::Vector{Vector{Dict{String,Int64}}}, scores::Vector{Int64}, hold_tolerence::Float64)

    if hold_tolerence < 0 || hold_tolerence > 1
        println("[WARNING] hold_tolerence must be a value between [0, 1]")
    end

    clean_states = Vector{Vector{Dict{String,Vector{Int64}}}}()
    clean_labels = Vector{Vector{Dict{String,Int64}}}()
    clean_scores = Int[]

    for (game_states, game_labels, game_score) in zip(states_lists, labels_lists, scores)
        hold_freq = get_label_stats_for_game(game_labels)[7]
        if !(hold_freq > hold_tolerence)
            push!(clean_states, game_states)
            push!(clean_labels, game_labels)
            push!(clean_scores, game_score)
        else
            println("Too many holds: $(hold_freq)")
        end
    end

    println("Sanity check: best score = $(clean_scores[end]) == 57600")
    println("Sanity check: filtered num games = $(length(clean_scores))")

    return clean_states, clean_labels, clean_scores
end

function select_games(N::Int64, states::Vector{Vector{Dict{String,Vector{Int64}}}}, labels::Vector{Vector{Dict{String,Int64}}}, ordered_scores::Vector{Int64})
    return states[end-N+1:end], labels[end-N+1:end], ordered_scores[end-N+1:end]
end

function assemble(states_list::Vector{Vector{Dict{String,Vector{Int64}}}}, labels_list::Vector{Vector{Dict{String,Int64}}})

    println("Sanity check: final num games = ", length(labels_list))

    states = [state for game_states in states_list for state in game_states]
    labels = [label for game_states in labels_list for label in game_states]

    println("Sanity check: num labels = ", length(labels))
    
    return states, labels

end

    
function shuffle(states::Vector{Dict{String,Vector{Int64}}}, labels::Vector{Dict{String,Int64}})
    tuples = collect(zip(states,labels))
    shuffle!(tuples)
    states, labels = unzip(tuples)
    return states, labels
end
    

function write_dataset(states::Vector{Dict{String,Vector{Int64}}}, labels::Vector{Dict{String,Int64}}, filename::AbstractString)
    json_states = JSON.json(states)
    json_labels = JSON.json(labels)

    states_path = joinpath(DATA_PATH, "states-" * filename)
    labels_path = joinpath(DATA_PATH, "labels-" * filename)
    
    open(states_path, "w") do states_file
        write(states_file, json_states)
    end

    open(labels_path, "w") do labels_file
        write(labels_file, json_labels)
    end

    return states_path, labels_path

end

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--N"
            help = "Size of the dataset"
            arg_type = Int
            default = DEFAULT_DATASET_SIZE
        "--hold_tolerence"
            help = "Tolerence of the number of hold action [0, 1]"
            arg_type = Float64
            default = DEFAULT_HOLD_TOLERENCE
        "--output"
            help = "Output filename in which to export the filtered dataset"
            arg_type = String
            default = DEFAULT_OUTPUT_FILE
        "--no_shuffle"
            help = "Disable the shuffling of the states-labels pairs between games."
            action = :store_false
        "--seed"
            help = "Shuffling seed for the states-labels pairs."
            arg_type = Int
            default = DEFAULT_SEED
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()
    println("Parameters: ")
    println("Seed: \t\t", args["seed"])
    println("hold_tolerence:\t", args["hold_tolerence"])
    println("shuffle:\t", !args["no_shuffle"])
    println("N:\t\t", args["N"])
    println("output:\t\t", args["output"])

    Random.seed!(args["seed"])

    # Decider limite
    states, labels, scores = collect_data()
    
    # Sort games in descending score order
    states, labels, scores = sort_games(states, labels, scores)
    
    # Clean up
    states, labels, scores = clean_games(states, labels, scores, args["hold_tolerence"])

    # Selection des meilleurs games
    states, labels, scores = select_games(args["N"], states, labels, scores)

    # Assembler les donnees
    states, labels = assemble(states, labels)
    
    # Shuffle (avec meme seed!)
    if args["no_shuffle"] == false
        states, labels = shuffle(states, labels)
    end

    # Write to file
    states_path, labels_path = write_dataset(states, labels, args["output"])
    println("Dataset successfully written to ", string(states_path), " and ", string(labels_path))

end

main()
   
