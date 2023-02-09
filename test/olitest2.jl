using JSON
using AWS
using AWS: @service
@service S3

function downloadData()
    cnt = (S3.list_objects("tetris-ai"))["Contents"]

    for i in cnt
        filename = i["Key"]
        print("$filename\n")
        if startswith(filename, "actions_")
            open("data/labels/$filename", "w") do f
                content = S3.get_object("tetris-ai", filename)
                JSON.print(f, String(content))
            end
            #downloadTo("data/labels", filename)
        elseif startswith(filename, "states_")
            #downloadTo("data/states", filename)
        else
            continue
        end
    end
end

function what()
    #AWSCredentials("AKIARNOH56OCXEW7GC6K", "OSubXlpEK53LUol4e9ruiyv1+hZE3zCi87WKgRSQ")
    #S3.AWSCredentials(profile="tetris")
    go = S3.get_object("tetris-ai", "action2.json")
    print(String(go))
end

function downloadTo(directory, file)
    open("$directory/$file", "w") do f
        content = S3.get_object("tetris-ai", file, Dict("response-content-type" => "application/json"))
        print(content)
        JSON.print(f, content)
    end
end

function uploadData()
    data = "{\"upload_v3\" : \"OK\"}"
    S3.put_object("tetris-ai", "upload3.json", Dict("body" => data))
end