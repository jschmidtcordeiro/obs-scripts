obs = obslua

-- Store the target scene name
local target_scene_name = ""

function script_description()
    return "Controls camera preset when switching to a specific scene"
end

function script_properties()
    local props = obs.obs_properties_create()
    local p = obs.obs_properties_add_list(props, "target_scene", "Target Scene", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    
    -- Get all scenes and add them to the dropdown
    local scenes = obs.obs_frontend_get_scenes()
    if scenes then
        for _, scene in ipairs(scenes) do
            local scene_name = obs.obs_source_get_name(scene)
            obs.obs_property_list_add_string(p, scene_name, scene_name)
        end
        obs.source_list_release(scenes)
    end
    
    return props
end

function script_update(settings)
    target_scene_name = obs.obs_data_get_string(settings, "target_scene")
    print("[DEBUG] Target scene updated to: " .. target_scene_name)
    io.flush()
end

function control_camera()
    print("[DEBUG] Controlling camera...")
    io.flush()

    local command = [[curl -X POST "http://192.168.50.205/cmdparse" -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" --data-raw "ReqUserName=YWRtaW4=&ReqUserPwd=YWRtaW4=&CmdData={\"Cmd\":\"ReqPresetCtrl\",\"Content\":{\"PresetCmd\":\"Call\",\"PresetID\":2,\"PresetName\":\"MANIFESTACAO\"}}" --insecure]]

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

    if scene_name == target_scene_name then
        print("[DEBUG] Target scene detected, controlling camera...")
        io.flush()
        control_camera()
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