Base.@kwdef mutable struct ScoreBenchMark
    n::Int64
    linecolor               = [:orange :blue]
    labels::Array{String}   = ["Scores" "Nombre de ticks"]
    xlabel::String          = "Itérations"
    ylabel::String          = "Score"
    graph_steps::Int64      = round(n / 10)
    scores::Vector{Int64}
    ticks::Vector{Int64}
    i::Int64                = 0
    current_max_y           = 0 # Used for ylims when plotting
    xticks                  = 0:graph_steps:n # Will be updated everytime we append something to the list
    linewidth               = 2
end

function CreateScoreBenchMark(n::Int64)
    linecolor               = [:orange :blue]
    labels::Array{String}   = ["Scores" "Nombre de ticks"]
    xlabel::String          = "Itérations"
    ylabel::String          = "Score"
    graph_steps::Int64      = round(n / 10)
    i::Int64                = 0
    current_max_y           = 0 # Used for ylims when plotting
    xticks                  = 0:graph_steps:n # Will be updated everytime we append something to the list
    linewidth               = 2

    return ScoreBenchMark(n, linecolor, labels, xlabel, ylabel, graph_steps, Vector{Int64}(), Vector{Int64}(), i, current_max_y, xticks, linewidth)
end

"""
Appends the score of an episode and the number of ticks counted in that episode into the
list used to plot the benchmarks. Also keeps track of other information for more efficient
plotting.
"""
function append_score_ticks!(b::ScoreBenchMark, score::Int64, tick::Int64)
    append!(b.scores, score)
    append!(b.ticks, tick)
    b.i += 1

    biggest = max(score, tick)

    if biggest > b.current_max_y
        b.current_max_y = biggest
    end
end

"""
Updates the plots with the most up-to-date information
"""
function update_benchmark(b::ScoreBenchMark, update_rate::Int64)
    if (b.i % update_rate) == 0
        plot(1:b.i,
            [b.scores, b.ticks],
            xlims=(0, b.n),
            xticks=b.xticks,
            ylims=(0, b.current_max_y),
            title=string("Agent performance over ", b.n, " games"),
            linecolor = [:orange :blue],
            linewidth = b.linewidth,
            label=b.labels)
        xlabel!("Itérations")
        ylabel!("Score")
        display(plot!(legend=:outerbottom, legendcolumns=2))
    end
end