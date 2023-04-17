using DataFrames
using CSV
using Statistics

default_results_path = "./results"

Base.@kwdef mutable struct ScoreBenchMark
    n::Int64
    linecolor               = [:orange :blue]
    labels::Array{String}   = ["Scores" "Ticks" "Rewards"]
    xlabel::String          = "Iterations"
    ylabel::String          = "Score"
    graph_steps::Int64      = ceil(n / 10)
    df::DataFrame           = DataFrame(Scores = Int64[], Ticks = Int64[], Rewards = Int64[])
    i::Int64                = 0
    current_max_y           = 0 # Used for ylims when plotting
    xticks                  = 0:graph_steps:n # Will be updated everytime we append something to the list
    linewidth               = 2
end

"""
    append_score_ticks!(b::ScoreBenchMark, score::Int64, tick::Int64, reward::Int64 = 0)

Appends the score of an episode and the number of ticks counted in that episode into the
list used to plot the benchmarks. Also keeps track of other information for more efficient
plotting.
"""
function append_score_ticks!(b::ScoreBenchMark, score::Int64, tick::Int64, reward::Int64 = 0)
    push!(b.df, [score, tick, reward])
    b.i += 1

    biggest = max(score, tick, reward)

    if biggest > b.current_max_y
        b.current_max_y = biggest
    end
end

"""
    update_benchmark(b::ScoreBenchMark, update_rate::Int64)

Updates the plots with the most up-to-date information. 
"""
function update_benchmark(b::ScoreBenchMark, update_rate::Int64, iter, render::Bool = true)
    if (b.i % update_rate) == 0

        if render
            plot(Matrix(b.df),
                xlims=(0, b.n),
                xticks=b.xticks,
                ylims=(0, b.current_max_y),
                title=string("Agent performance over ", b.n, " games"),
                linecolor = [:orange :blue],
                linewidth = b.linewidth,
                label=b.labels)
            xlabel!("Iterations")
            display(plot!(legend=:outerbottom, legendcolumns=3))
        else
            means = mean.(eachcol(last(b.df, update_rate)))
            println(iter, "Avg score: ", means[1], " Avg ticks: ", means[2], " Avg rewards: ", means[3])
        end
    end
end

"""
    save_to_csv(benchmark::ScoreBenchMark, run_id::String, verbose::Bool = false)

Save benchmark data as a CSV file. The name of the file is provided as an argument.
The path doesn't support Windows' backslashes. By default, the results are saved to
the "./results" directory.
"""
function save_to_csv(benchmark::ScoreBenchMark, agent_type::String, run_id::String, verbose::Bool = true)
    
    if isempty(run_id)
        prefix = agent_type
        suffix = Dates.format(DateTime(now()), "yyyymmddHHMMSS")
        run_id = "$prefix-$suffix"
    end

    filename = run_id * ".csv"

    # Find the right directory to save
    pre_path = ""
    complete_path = ""
    pos = findlast('/', filename)
    if isnothing(pos)
        pre_path = default_results_path
        complete_path = joinpath(pre_path, filename)
    else
        pre_path = filename[1:pos]
        if !isdirpath(pre_path)
            println("Error: The path provided is not a valid path.")
            return false
        end

        complete_path = filename
    end

    mkpath(pre_path)

    file = CSV.write(complete_path, benchmark.df)
    if verbose
        println("The benchmark data was saved to ", file)
    end

    return true
end