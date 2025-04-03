obs = obslua

function script_load(settings)
    print("[DEBUG] Script started...")  -- Ensure script starts
    io.flush()  -- Force output flush

    -- For Windows, use double quotes for outer quoting and escape inner double quotes
    local command = [[curl -X POST "http://192.168.50.205/cmdparse" -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" --data-raw "ReqUserName=YWRtaW4=&ReqUserPwd=YWRtaW4=&CmdData={\"Cmd\":\"ReqPresetCtrl\",\"Content\":{\"PresetCmd\":\"Call\",\"PresetID\":2,\"PresetName\":\"MANIFESTACAO\"}}" --insecure]]

    local handle = io.popen(command .. " 2>&1")  -- Run command and capture output

    if handle then
        local result = handle:read("*a")  -- Read output
        handle:close()  -- Close handle

        print("[DEBUG] cURL Response:\n" .. result)  -- Print output in OBS log
        io.flush()  -- Force output flush
    else
        print("[ERROR] Failed to execute cURL command")
        io.flush()  -- Ensure error message is visible
    end
end

script_load()