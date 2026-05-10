local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

--- @module "core.wand_utils"
local wand_utils = dofile_once(core_path .. "wand_utils.lua")

--- @module "core.player_utils"
local player_utils = dofile_once(core_path .. "player_utils.lua")

--- @module "core.logger"
local logger = dofile_once(core_path .. "logger.lua")

--- @module "core.wand_attributes"
local WandAttribs = dofile_once(core_path .. "wand_attributes.lua")

--- @class wand_helper_tool
local M = {
    name = "Wand Helper",
    is_open = false
}

local should_clear_cast_delay = false
local should_clear_recharge_time = false
local should_dupe_actions = true


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


        if imgui.CollapsingHeader("Wand Duplication") then

            local _
            _, should_dupe_actions = imgui.Checkbox(
                "Should Dupe Actions", should_dupe_actions
            )

            if imgui.Button("Duplicate and Spawn Held wand at Player") then
                local wnd_attribs = WandAttribs.from_wand_entity(held_wand_id)

                local player_id = player_utils.get_first_player_id()

                if player_id == nil then
                    logger.log_info("Cannot spawn, Reason: cannot find player")
                else
                    local x, y = EntityGetTransform(player_id)

                    local wand_id = wand_utils.spawn_default_wand_at(x, y)
                    logger.log_info("Wand Spawned at player")

                    wnd_attribs:apply_to(wand_id)
                    logger.log_info("Wand attributes applied")

                    if should_dupe_actions then
                        local action_ids = wand_utils.wand_get_all_action_ids(
                            held_wand_id
                        )

                        -- NOTE: its possible that there are less slots than there are actions
                        -- we ignore them for now since the cap is set above.
                        wand_utils.wand_append_action_ids(wand_id, action_ids, false)
                    end
                end
            end

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
