obs = obslua

-- Store the target scenes and their presets
local target_scenes = {}
local settings = nil

-- Define available camera presets
local camera_presets = {
    {name = "Mesa1", id = 0},
    {name = "MANIFESTACAO", id = 2},
    {name = "PORTA1", id = 7},
    {name = "PORTA2", id = 3},
    {name = "Mesa5", id = 4}
}

function script_description()
    return "Controls camera preset when switching to specific scenes"
end

function script_properties()
    local props = obs.obs_properties_create()
    
    -- Add a list for scene selection
    local p = obs.obs_properties_add_list(props, "scene_to_add", "Scene to Add", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
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
    
    -- Add camera preset selection
    local preset_p = obs.obs_properties_add_list(props, "camera_preset", "Camera Preset", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    for _, preset in ipairs(camera_presets) do
        obs.obs_property_list_add_string(preset_p, preset.name, preset.name)
    end
    
    -- Add button to add scene
    obs.obs_properties_add_button(props, "add_scene", "Add Scene", function(props, property)
        if not settings then return true end
        
        local scene_name = obs.obs_data_get_string(settings, "scene_to_add")
        local preset_name = obs.obs_data_get_string(settings, "camera_preset")
        
        if scene_name and scene_name ~= "" and preset_name and preset_name ~= "" then
            -- Get current scenes
            local current_scenes = obs.obs_data_get_array(settings, "selected_scenes") or obs.obs_data_array_create()
            
            -- Check if scene is already added
            local scene_exists = false
            local count = obs.obs_data_array_count(current_scenes)
            for i = 0, count - 1 do
                local item = obs.obs_data_array_item(current_scenes, i)
                if obs.obs_data_get_string(item, "scene_name") == scene_name then
                    scene_exists = true
                    obs.obs_data_release(item)
                    break
                end
                obs.obs_data_release(item)
            end
            
            if not scene_exists then
                -- Add new scene with preset
                local new_scene = obs.obs_data_create()
                obs.obs_data_set_string(new_scene, "scene_name", scene_name)
                obs.obs_data_set_string(new_scene, "preset_name", preset_name)
                obs.obs_data_array_push_back(current_scenes, new_scene)
                obs.obs_data_release(new_scene)
                
                -- Update settings
                obs.obs_data_set_array(settings, "selected_scenes", current_scenes)
                obs.obs_data_array_release(current_scenes)
                
                -- Update target scenes
                script_update(settings)
            end
        end
        return true
    end)
    
    -- Add button to clear all scenes
    obs.obs_properties_add_button(props, "clear_scenes", "Clear All Scenes", function(props, property)
        if not settings then return true end
        
        local empty_array = obs.obs_data_array_create()
        obs.obs_data_set_array(settings, "selected_scenes", empty_array)
        obs.obs_data_array_release(empty_array)
        script_update(settings)
        return true
    end)

    return props
end

function script_update(new_settings)
    settings = new_settings
    -- Clear previous scenes
    target_scenes = {}
    
    -- Get all selected scenes
    local scenes_array = obs.obs_data_get_array(settings, "selected_scenes")
    if scenes_array then
        local count = obs.obs_data_array_count(scenes_array)
        for i = 0, count - 1 do
            local scene = obs.obs_data_array_item(scenes_array, i)
            if scene then
                local scene_name = obs.obs_data_get_string(scene, "scene_name")
                local preset_name = obs.obs_data_get_string(scene, "preset_name")
                if scene_name ~= "" and preset_name ~= "" then
                    table.insert(target_scenes, {
                        scene_name = scene_name,
                        preset_name = preset_name
                    })
                end
                obs.obs_data_release(scene)
            end
        end
        obs.obs_data_array_release(scenes_array)
    end
    
    -- Update the current pairs list
    local props = script_properties()
    local current_pairs = obs.obs_properties_get(props, "current_pairs")
    obs.obs_property_list_clear(current_pairs)
    obs.obs_property_list_add_string(current_pairs, "", "")
    
    for _, scene in ipairs(target_scenes) do
        local pair_text = string.format("%s -> %s", scene.scene_name, scene.preset_name)
        obs.obs_property_list_add_string(current_pairs, pair_text, pair_text)
    end
    
    print("[DEBUG] Current target scenes and presets:")
    for i, scene in ipairs(target_scenes) do
        print(string.format("[DEBUG] %d. Scene: %s, Preset: %s", i, scene.scene_name, scene.preset_name))
    end
    io.flush()
end

function control_camera(preset_name)
    print("[DEBUG] Controlling camera to preset: " .. preset_name)
    io.flush()

    -- Find the preset ID for the given preset name
    local preset_id = 0
    for _, preset in ipairs(camera_presets) do
        if preset.name == preset_name then
            preset_id = preset.id
            break
        end
    end

    -- Create the JSON payload
    local json_data = string.format("{\\\"Cmd\\\":\\\"ReqPresetCtrl\\\",\\\"Content\\\":{\\\"PresetCmd\\\":\\\"Call\\\",\\\"PresetID\\\":%d,\\\"PresetName\\\":\\\"%s\\\"}}", preset_id, preset_name)
    
    -- Windows command
    local command = string.format('curl -X POST \"http://192.168.50.205/cmdparse\" -H \"Content-Type: application/x-www-form-urlencoded;charset=UTF-8\" --data-raw \"ReqUserName=YWRtaW4=&ReqUserPwd=YWRtaW4=&CmdData=%s\" --insecure', json_data)
    
    print("[DEBUG] Command: " .. command)
    io.flush()

    -- Execute command using os.execute for Windows
    local success = os.execute(command)
    local result = success and "Command executed successfully" or "Command execution failed"

    print("[DEBUG] Command result: " .. result)
    io.flush()
end

function on_scene_change(current_scene)
    if not current_scene then return end
    
    local scene_name = obs.obs_source_get_name(current_scene)
    if not scene_name then return end
    
    print("[DEBUG] Scene changed to: " .. scene_name)
    io.flush()

    -- Check if the current scene is in our target scenes list
    print("[DEBUG] Target scenes:")
    for _, target_scene in ipairs(target_scenes) do
        print(string.format("[DEBUG] %s -> %s", target_scene.scene_name, target_scene.preset_name))
    end
    io.flush()
    for _, target_scene in ipairs(target_scenes) do
        if scene_name == target_scene.scene_name then
            print("[DEBUG] Target scene detected, controlling camera to preset: " .. target_scene.preset_name)
            io.flush()
            control_camera(target_scene.preset_name)
            break
        end
    end
end

function script_load(settings)
    print("[DEBUG] Script loaded...")
    io.flush()
    
    -- Register the scene change callback
    obs.obs_frontend_add_event_callback(function(event)
        if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
            local current_scene = obs.obs_frontend_get_current_scene()
            if current_scene then
                on_scene_change(current_scene)
                obs.obs_source_release(current_scene)
            end
        end
    end)
end