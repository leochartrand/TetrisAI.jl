using CSV, Plots, DataFrames, ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "file_id"
            help = "AgentType-RunId"
            arg_type = String
        "--result_dir"
            help = "The folder where the csv file is."
            arg_type = String
            default = "./results/"
        "--export"
            help = "Full path of the plot image to export."
            arg_type = String
            default = "./results/export.pdf"
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()

    if isnothing(args["file_id"])
        println("See usage. You need to provide the file_id of the results you want to plot.")
        return
    end

    # Load data from CSV file
    filename    = args["result_dir"] * args["file_id"] * ".csv"
    df          = CSV.File(filename) |> DataFrame
    n           = length(df.Scores)
    graph_steps = ceil(n / 10) - 1
    xticks      = 0:graph_steps:n
    max_y       = max(maximum(df.Scores), maximum(df.Ticks), maximum(df.Rewards))

    plot(Matrix(df),
        xlims=(0, n),
        xticks=xticks,
        ylims=(0, max_y),
        title=string("Agent performance over ", n, " games"),
        linecolor = [:orange :blue :red],
        linewidth = 2,
        label=["Scores" "Ticks" "Rewards"])
    xlabel!("Iterations")

    x = plot!(legend=:outerbottom, legendcolumns=3)
    
    if !isnothing(args["export"])
        savefig(args["export"])
        println("Success: Figure exported to ", args["export"])
    end

    display(x)

    println("Press RETURN to end the visualization.")
    readline() # Waits for user input. Used to keep the plot open.
end

main()

