import ..TetrisAI.PROJECT_ROOT
using JSON
using AWS: @service
@service S3

const BUCKET_NAME = "tetris-ai"
const SCOREBOARD = "scoreboard"

global game_over = false
global data_list = []

set_game() = (global game_over = !game_over)

#Checks if new data ready to upload. If not tries again in 1 sec
function process_data()
    while(!game_over)
        if isempty(data_list)
            sleep(1)
        else
            upload_data()
        end
    end
end

function upload_data()

    for data in data_list
        arr = []

        #TODO: not working with profile. Not sure why??
        #AWSCredentials(profile="tetris")

        suffix = data["suffix"]
        score = data["score"]
        stateFile = data["stateFile"]
        actionFile = data["actionFile"]
        stateFileName = data["stateFileName"]
        actionFileName = data["actionFileName"]
        states = data["states"]
        labels = data["labels"]

        open(stateFileName, "w") do f
            for (idx, state) in states
                state = Dict("state$idx" => state)
                push!(arr, state)
            end
            S3.put_object(BUCKET_NAME, stateFile, Dict(
                "body" => JSON.json(arr), 
                "Content-Type" => "application/json"))
            JSON.print(f, arr)
        end

        empty!(arr)
        open(actionFileName, "w") do f
            for (idx, label) in labels
                label = Dict("label$idx" => label)
                push!(arr, label)
            end
            S3.put_object(BUCKET_NAME, actionFile, Dict(
                "body" => JSON.json(arr),
                "Content-Type" => "application/json"))
            JSON.print(f, arr)
        end
        scoreboard_append(suffix, score)
    end
    empty!(data_list)
end

function scoreboard_append(name, score)
    content = S3.get_object(BUCKET_NAME, SCOREBOARD, Dict("response-content-type" => "text/plain"))
    new_score = "$content\n$name : $score"
    S3.put_object(BUCKET_NAME, SCOREBOARD, Dict(
        "body" => new_score,
        "Content-Type" => "text/plain"))
end

function download_data()    
    #TODO: use profile
    #AWSCredentials(profile=PROFILE)
    cnt = (S3.list_objects(BUCKET_NAME))["Contents"]

    for i in cnt
        filename = i["Key"]
        if startswith(filename, "actions_")
            download_to(LABELS_PATH, filename)
        elseif startswith(filename, "states_")
            download_to(STATES_PATH, filename)
        else
            continue
        end
    end
end

function download_to(directory, file)
    open("$directory/$file", "w") do f
        content = S3.get_object(BUCKET_NAME, file, Dict("response-content-type" => "application/json"))
        JSON.print(f, content)
    end
end
