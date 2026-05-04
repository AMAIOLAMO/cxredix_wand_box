local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

-- @module core.wand_utils
dofile_once(core_path .. "wand_utils.lua")

-- @module core.player_utils
dofile_once(core_path .. "player_utils.lua")

local M = {
    name = "Wand Helper",
    is_open = false
}


function M.render_window(imgui, wndbox_state)
    if imgui.Button("Force wand refresh") then
        force_refresh_all_wands_on_player(
            get_player_id(wndbox_state.picked_player_idx)
        )
        wndbx_log_info("Refresh Complete")
    end

    if imgui.Button("Copy held wand str") then
        local held_wand_id = get_held_wand_id(get_first_player_id())

        if held_wand_id == nil then
            wndbx_log_info("Cannot find held wand on the first player")
        else
            GamePrint("found player and held wand")

            local actions_str = wand_get_all_actions_as_actions_str(
                held_wand_id
            )

            imgui.SetClipboardText(actions_str)

            wndbx_log_info(
                string.format("Copy complete, total of %d characters", #actions_str)
            )
        end
    end
end

return M
