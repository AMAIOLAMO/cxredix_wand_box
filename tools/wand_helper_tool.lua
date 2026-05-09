local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

--- @module "core.wand_utils"
local wand_utils = dofile_once(core_path .. "wand_utils.lua")

--- @module "core.player_utils"
local player_utils = dofile_once(core_path .. "player_utils.lua")

--- @module "core.logger"
local logger = dofile_once(core_path .. "logger.lua")

--- @class wand_helper_tool
local M = {
    name = "Wand Helper",
    is_open = false
}

local should_clear_cast_delay = false
local should_clear_recharge_time = false


function M.render_window(imgui, wndbox_state)
    imgui.Text(
        "Warning: May not support multiplayer reliably yet :)"
    )

    imgui.Text(
        string.format("Targeting player: [%d]", wndbox_state.picked_player_idx)
    )

    -- TODO: allow for wand multi selection, instead of ONLY the held wand
    local held_wand_id = wand_utils.get_held_wand_id(
        player_utils.get_player_id(wndbox_state.picked_player_idx)
    )

    imgui.Separator()

    imgui.Text("Applied on 'held wand'")

    -- TODO: make this part, multiplayer friendly

    if held_wand_id ~= nil then
        if imgui.Button("Clear all wand actions") then
            wand_utils.wand_clear_all_actions(held_wand_id)
        end

        if imgui.Button("Copy wand str") then
            logger.log_info("found player and held wand")

            local actions_str = wand_utils.wand_get_all_actions_as_actions_str(
                held_wand_id
            )

            imgui.SetClipboardText(actions_str)

            logger.log_info(
                string.format("Copy complete, total of %d characters", #actions_str)
            )
        end

        if imgui.CollapsingHeader("Clear Delays") then
            M.show_delay_clearing(imgui, held_wand_id)
        end

        if imgui.Button("Duplicate and Spawn Held wand at Player") then
            logger.log_info("Not yet done! Coming soon :)")
        end

    else
        imgui.BulletText("No held wand found. Please let the target player hold a wand.")
    end


    imgui.Separator()

    imgui.Text("Applied on 'gun.lua'")
    if imgui.Button("Force wand refresh") then
        wand_utils.force_refresh_all_wands_on_player(
            player_utils.get_player_id(wndbox_state.picked_player_idx)
        )
        logger.log_info("Refresh Complete")
    end
end

function M.show_delay_clearing(imgui, held_wand_id)
    local _
    _, should_clear_cast_delay = imgui.Checkbox(
        "Cast Delay", should_clear_cast_delay
    )

    _, should_clear_recharge_time = imgui.Checkbox(
        "Recharge Time", should_clear_recharge_time
    )

    if imgui.Button("Clear Selected Delay(s)") then
        local ability_comp = EntityGetFirstComponentIncludingDisabled(
            held_wand_id, "AbilityComponent"
        )

        local current_frame = GameGetFrameNum()

        if should_clear_cast_delay then
            ComponentSetValue2(ability_comp, "mNextFrameUsable", current_frame)

            logger.log_info("Cleared Cast Delay")
        end

        if should_clear_recharge_time then
            ComponentSetValue2(ability_comp, "mReloadFramesLeft", 0)
            ComponentSetValue2(ability_comp, "mReloadNextFrameUsable", current_frame)

            logger.log_info("Cleared reload time")
        end
    end
end

return M
