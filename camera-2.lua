obs = obslua

-- Store the target scene names
local target_scenes = {}

function script_description()
    return "Controls camera preset when switching to specific scenes"
end

function script_properties()
    local props = obs.obs_properties_create()
    local p = obs.obs_properties_add_list(props, "target_scenes", "Target Scenes", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    obs.obs_property_list_add_string(p, "", "")  -- Add empty option
    
    -- Get all scenes and add them to the dropdown
    local scenes = obs.obs_frontend_get_scenes()
    if scenes then
        for _, scene in ipairs(scenes) do
            local scene_name = obs.obs_source_get_name(scene)
            obs.obs_property_list_add_string(p, scene_name, scene_name)
        end
        obs.source_list_release(scenes)
    end
    
    -- Add a button to add more scenes
    obs.obs_properties_add_button(props, "add_scene", "Add Another Scene", function(props, property)
        local p = obs.obs_properties_get(props, "target_scenes")
        obs.obs_property_list_clear(p)
        obs.obs_property_list_add_string(p, "", "")
        
        local scenes = obs.obs_frontend_get_scenes()
        if scenes then
            for _, scene in ipairs(scenes) do
                local scene_name = obs.obs_source_get_name(scene)
                obs.obs_property_list_add_string(p, scene_name, scene_name)
            end
            obs.source_list_release(scenes)
        end
        return true
    end)
    
    return props
end

function script_update(settings)
    -- Clear previous scenes
    target_scenes = {}
    
    -- Get all selected scenes
    local count = obs.obs_data_get_array_count(settings, "target_scenes")
    for i = 0, count - 1 do
        local scene = obs.obs_data_get_array_item(settings, "target_scenes", i)
        if scene then
            local scene_name = obs.obs_data_get_string(scene, "value")
            if scene_name ~= "" then
                table.insert(target_scenes, scene_name)
            end
            obs.obs_data_release(scene)
        end
    end
    
    print("[DEBUG] Target scenes updated to: " .. table.concat(target_scenes, ", "))
    io.flush()
end

function control_camera()
    print("[DEBUG] Controlling camera...")
    io.flush()

    local command = [[curl -X POST "http://192.168.50.205/cmdparse" -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" --data-raw "ReqUserName=YWRtaW4=&ReqUserPwd=YWRtaW4=&CmdData={\"Cmd\":\"ReqPresetCtrl\",\"Content\":{\"PresetCmd\":\"Call\",\"PresetID\":0,\"PresetName\":\"Mesa1\"}}" --insecure]]

    local handle = io.popen(command .. " 2>&1")

    if handle then
        local result = handle:read("*a")
        handle:close()

        print("[DEBUG] cURL Response:\n" .. result)
        io.flush()
    else
        print("[ERROR] Failed to execute cURL command")
        io.flush()
    end
end

function on_scene_change(current_scene)
    local scene_name = obs.obs_source_get_name(current_scene)
    print("[DEBUG] Scene changed to: " .. scene_name)
    io.flush()

    -- Check if the current scene is in our target scenes list
    for _, target_scene in ipairs(target_scenes) do
        if scene_name == target_scene then
            print("[DEBUG] Target scene detected, controlling camera...")
            io.flush()
            control_camera()
            break
        end
    end
end

function script_load(settings)
    print("[DEBUG] Script loaded...")
    io.flush()
    
    -- Register the scene change callback
    obs.obs_frontend_add_event_callback(function(event, data)
        if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
            on_scene_change(obs.obs_frontend_get_current_scene())
        end
    end)
end 