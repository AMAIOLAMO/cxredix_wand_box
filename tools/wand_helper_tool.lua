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

--- @module "core.imgui_utils"
local imgui_utils = dofile_once(core_path .. "imgui_utils.lua")


--- @class tools.wand_helper_tool
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

        if imgui.Button("Copy wand actions str") then
            logger.info("found player and held wand")

            local actions_str = wand_utils.wand_get_all_actions_as_actions_str(
                held_wand_id
            )

            imgui.SetClipboardText(actions_str)

            logger.info(
                string.format("Copy complete, total of %d characters", #actions_str)
            )
        end

        if imgui.CollapsingHeader("Clear Delays") then
            imgui.Indent()
            M.show_delay_clearing(imgui, held_wand_id)
            imgui.Unindent()
        end


        if imgui.CollapsingHeader("Wand Duplication") then
            imgui.Indent()

            local _
            _, should_dupe_actions = imgui.Checkbox(
                "Should Dupe Actions", should_dupe_actions
            )

            if imgui.Button("Duplicate and Spawn Held wand at Player") then
                local wnd_attribs = WandAttribs.from_wand_entity(held_wand_id)

                local player_id = player_utils.get_first_player_id()

                if player_id == nil then
                    logger.info("Cannot spawn, Reason: cannot find player")
                else
                    local x, y = EntityGetTransform(player_id)

                    local wand_id = wand_utils.spawn_default_wand_at(x, y)
                    logger.info("Wand Spawned at player")

                    wnd_attribs:apply_to(wand_id)
                    logger.info("Wand attributes applied")

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

            imgui.Unindent()
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
        logger.info("Refresh Complete")
    end

    imgui.Separator()

    local player_id = player_utils.get_player_id(
        wndbox_state.picked_player_idx
    )

    M.display_wand_radar(imgui, player_id)
end

function M.display_wand_radar(imgui, player_id)
    imgui.Text("Wand Radar")
    local wand_ids = EntityGetWithTag("wand") or {}

    imgui.Indent()

    local px, py = EntityGetTransform(player_id)

    for i, wand_id in ipairs(wand_ids) do
        local wx, wy = EntityGetTransform(wand_id)

        local dx = px - wx
        local dy = py - wy

        local dist_to_player_px = math.sqrt(dy * dy + dx * dx)

        if imgui.CollapsingHeader(string.format("ID: %d", i, wand_id)) then
            imgui.BulletText(
                string.format(
                    "<%.0f, %.0f> (%.1f px)", wx, wy, dist_to_player_px
                )
            )

            imgui.PushID(tostring(wand_id))

            if imgui.Button("Tp to wand") then
                EntityApplyTransform(player_id, wx, wy)
            end

            imgui.SameLine()

            if imgui.Button("Tp wand to you") then
                EntityApplyTransform(wand_id, px, py)
            end

            imgui.SameLine()

            if imgui_utils.cautious_button(imgui, "Destroy") then
                EntityKill(wand_id)
            end

            imgui.PopID(tostring(wand_id))
        end

    end

    imgui.Unindent()
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

            logger.info("Cleared Cast Delay")
        end

        if should_clear_recharge_time then
            ComponentSetValue2(ability_comp, "mReloadFramesLeft", 0)
            ComponentSetValue2(ability_comp, "mReloadNextFrameUsable", current_frame)

            logger.info("Cleared reload time")
        end
    end
end

return M
