local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

-- @module core.wand_utils
dofile_once(core_path .. "wand_utils.lua")

-- @module core.player_utils
dofile_once(core_path .. "player_utils.lua")

dofile_once(core_path .. "logger.lua")

local M = {
    name = "Wand Helper",
    is_open = false
}


function M.render_window(imgui, wndbox_state)
    imgui.Text(
        "Warning: May not support multiplayer reliably yet :)"
    )

    imgui.Text(
        string.format("Targeting player: [%d]", wndbox_state.picked_player_idx)
    )

    -- TODO: allow for wand multi selection, instead of ONLY the held wand
    local held_wand_id = get_held_wand_id(
        get_player_id(wndbox_state.picked_player_idx)
    )

    imgui.Separator()

    imgui.Text("Applied on 'held wand'")

    -- TODO: make this part, multiplayer friendly

    if held_wand_id ~= nil then
        if imgui.Button("Clear all wand actions") then
            wand_clear_all_actions(held_wand_id)
        end

        if imgui.Button("Copy wand str") then
            wndbx_log_info("found player and held wand")

            local actions_str = wand_get_all_actions_as_actions_str(
                held_wand_id
            )

            imgui.SetClipboardText(actions_str)

            wndbx_log_info(
                string.format("Copy complete, total of %d characters", #actions_str)
            )
        end

        if imgui.Button("Clear Cast Delay") then
            local ability_comp = EntityGetFirstComponentIncludingDisabled(
                held_wand_id, "AbilityComponent"
            )

            local current_frame = GameGetFrameNum()
            
            ComponentSetValue2(ability_comp, "mNextFrameUsable", current_frame)

            wndbx_log_info("Cleared Cast Delay")
        end

        if imgui.Button("Clear Recharge time") then
            local ability_comp = EntityGetFirstComponentIncludingDisabled(
                held_wand_id, "AbilityComponent"
            )

            local current_frame = GameGetFrameNum()

            ComponentSetValue2(ability_comp, "mReloadFramesLeft", 0)
            ComponentSetValue2(ability_comp, "mReloadNextFrameUsable", current_frame)

            wndbx_log_info("Cleared reload time")
        end
    else
        imgui.BulletText("No held wand found. Please let the target player hold a wand.")
    end
    


    imgui.Separator()

    imgui.Text("Applied on 'gun.lua'")
    if imgui.Button("Force wand refresh") then
        force_refresh_all_wands_on_player(
            get_player_id(wndbox_state.picked_player_idx)
        )
        wndbx_log_info("Refresh Complete")
    end
end

return M
