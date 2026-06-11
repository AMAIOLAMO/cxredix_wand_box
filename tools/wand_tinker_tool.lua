local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

--- @module "core.player_utils"
local player_utils = dofile_once(core_path .. "player_utils.lua")

--- @module "core.profile_timer"
local ProfileTimer = dofile_once(core_path .. "profile_timer.lua")

--- @module "core.wand_utils"
local wand_utils = dofile_once(core_path .. "wand_utils.lua")

--- @module "core.math_utils"
local umath = dofile_once(core_path .. "math_utils.lua")

--- @module "core.logger"
local logger = dofile_once(core_path .. "logger.lua")

--- @module "core.wand_attributes"
local WandAttribs = dofile_once(core_path .. "wand_attributes.lua")

--- @module "core.category_kv_map"
local CategoryKVMap = dofile_once(core_path .. "category_kv_map.lua")
---
--- @module "core.category_kv_map_imgui"
local CategoryKVMapImgui = dofile_once(core_path .. "category_kv_map_imgui.lua")

--- @module "core.imgui_utils"
local imgui_utils = dofile_once(core_path .. "imgui_utils.lua")

--- @class tools.wand_tinker_tool
local M = {
    name = "Wand Tinker",
    is_open = false
}


local TIME_UNIT_OPTS = {
    "frames", "in game seconds"
}

local time_unit_used = "frames"

local wnd_attribs = WandAttribs.new_default()


local should_limit_to_valid_values = true

local wand_stat_presets_settings_key = "cxredix_wand_box.wand_stat_presets"

local wand_stat_presets = nil

local wand_stat_preset_save_category = "Any"
local wand_stat_preset_save_name = "MyCoolStats"

local wand_stat_presets_req_save = false

local wand_stat_presets_open = false

function M.on_world_init()
    wand_stat_presets = CategoryKVMap.load_from_settings(
        wand_stat_presets_settings_key
    )
end

function M.on_world_post_update()
    if wand_stat_presets_req_save then
        wand_stat_presets_req_save = false
    
        wand_stat_presets:save_to_settings(wand_stat_presets_settings_key)
        logger.info("Action Detected, Saved Wand Stat Presets")
    end
end

function M.render_window(imgui, wndbx_state)
    imgui.Text(
        "Warning: May not support multiplayer reliably yet :)"
    )

    -- local wand_picked_changed, picked_wand_idx = imgui.InputInt(
    --     "##PickedWandIdx", picked_wand_idx
    -- )
    --
    -- imgui.BulletText(
    --     string.format("Picked wand [%d]", picked_wand_idx)
    -- )

    -- TODO: link this with the wand picker above
    local picked_player_id = player_utils.get_first_player_id()
    local picked_wand_id = wand_utils.get_held_wand_id(
        picked_player_id
    )


    if picked_wand_id == nil then
        imgui.Text(
            "Cannot find the specified wand"
        )

        imgui.BulletText("Did you pick the right player?(Picking of players coming soon :D)")
        imgui.BulletText("Is the player currently holding a wand?")
        return
    end

    
    -- TODO: repeated a bit between wand_loader_tool and here
    local overall_tbl_flags = bit.bor(
        imgui.TableFlags.Resizable,
        imgui.TableFlags.Hideable,
        imgui.TableFlags.RowBg
    )

    local col_count = wand_stat_presets_open and 2 or 1

    if imgui.BeginTable("##TableWandTinkerer", col_count, overall_tbl_flags) then
        for i = 1, col_count do
            imgui.TableSetupColumn("")
        end

        imgui.TableNextRow()

        -- Regular
        imgui.TableNextColumn()
        M.render_tinker_section(imgui, wndbx_state, picked_player_id, picked_wand_id)

        if imgui_utils.green_button(imgui, "Toggle Wand Presets") then
            wand_stat_presets_open = not wand_stat_presets_open
        end


        if wand_stat_presets_open and wand_stat_presets and col_count > 1 then
            imgui.TableNextColumn()

            imgui.Separator()

            if imgui.Button(">") then
                wand_stat_presets_open = false
            end

            imgui.SameLine()
            imgui.Text("Wand Stat Presets")

            imgui.Indent()
            M.render_stat_presets(imgui, picked_player_id, picked_wand_id)
            imgui.Unindent()
        end

        imgui.EndTable()
    end

end

function M.render_tinker_section(imgui, wndbx_state, picked_player_id, picked_wand_id)
    imgui.Separator()

    imgui.BulletText(
        string.format("Applies on held wand of id: %d", picked_wand_id)
    )

    if imgui.BeginCombo("Use time unit", time_unit_used) then
        for _, value in ipairs(TIME_UNIT_OPTS) do
            if imgui.Selectable(value, value == time_unit_used) then
                time_unit_used = value
            end
        end

        imgui.EndCombo()
    end

    local function frames_to_secs(f)
        return f * (1.0 / 60.0)
    end

    local function secs_to_frames_floored(s)
        local frames_frac = s * (60.0 / 1.0)

        return math.floor(frames_frac)
    end

    local should_limit_to_valid_values_changed
    should_limit_to_valid_values_changed, should_limit_to_valid_values = imgui.Checkbox(
        "Limit Values in Valid Range", should_limit_to_valid_values
    )

    if imgui.CollapsingHeader("UI & HUD") then
        imgui.Indent()

        local _

        _, wnd_attribs.item_name = imgui.InputText(
            "Wand Name", wnd_attribs.item_name
        )

        _, wnd_attribs.always_use_item_name_in_ui = imgui.Checkbox(
            "Always show wand name in UI", wnd_attribs.always_use_item_name_in_ui
        )

        imgui.Unindent()
    end


    if imgui.CollapsingHeader("Delays") then
        imgui.Indent()

        if time_unit_used == "frames" then
            local cd_frames_changed
            cd_frames_changed, wnd_attribs.cd_frames = imgui.InputInt(
                "Cast Delay(Frames)", wnd_attribs.cd_frames
            )

            local rt_frames_changed
            rt_frames_changed, wnd_attribs.rt_frames = imgui.InputInt(
                "Recharge Time(Frames)", wnd_attribs.rt_frames
            )

        elseif time_unit_used == "in game seconds" then
            local cd_secs_changed, cd_secs = imgui.InputFloat(
                "Cast Delay(Seconds)", frames_to_secs(wnd_attribs.cd_frames)
            )

            wnd_attribs.cd_frames = secs_to_frames_floored(cd_secs)

            local rt_secs_changed, rt_secs = imgui.InputFloat(
                "recharge time(seconds)", frames_to_secs(wnd_attribs.rt_frames)
            )

            wnd_attribs.rt_frames = secs_to_frames_floored(rt_secs)
        end
        imgui.Unindent()
    end


    if imgui.CollapsingHeader("Mana") then
        imgui.Indent()

        local mana_max_changed
        mana_max_changed, wnd_attribs.mana_max = imgui.InputInt(
            "Max Mana", wnd_attribs.mana_max
        )


        if time_unit_used == "in game seconds" then
            local mana_chrg_spd_secs_changed
            mana_chrg_spd_secs_changed, wnd_attribs.mana_chrg_spd_secs = imgui.InputInt(
                "Mana Charge Speed(Mana / Second)", wnd_attribs.mana_chrg_spd_secs
            )

        elseif time_unit_used == "frames" then
            local mana_chrg_spd_secs_changed, mana_chrg_spd_frame = imgui.InputInt(
                "Mana Charge Speed(Mana / Frame)",
                wnd_attribs.mana_chrg_spd_secs / 60
            )

            wnd_attribs.mana_chrg_spd_secs = mana_chrg_spd_frame * 60
        end

        imgui.Unindent()
    end

    if imgui.CollapsingHeader("Spells") then
        imgui.Indent()

        local should_shuffle_changed
        should_shuffle_changed, wnd_attribs.should_shuffle = imgui.Checkbox(
            "Should Shuffle", wnd_attribs.should_shuffle
        )

        local spells_per_cast_changed
        spells_per_cast_changed, wnd_attribs.spells_per_cast = imgui.InputInt(
            "Spells per Cast", wnd_attribs.spells_per_cast
        )

        local capacity_changed
        capacity_changed, wnd_attribs.deck_capacity = imgui.InputInt(
            "Capacity", wnd_attribs.deck_capacity
        )

        local spread_degrees_changed
        -- TODO: allow radians :)

        spread_degrees_changed, wnd_attribs.spread_degrees = imgui.InputFloat(
            "Spread(degrees)", wnd_attribs.spread_degrees
        )

        local proj_spd_multiplier_changed
        proj_spd_multiplier_changed, wnd_attribs.proj_spd_multiplier = imgui.InputFloat(
            "Projectile Speed Multiplier", wnd_attribs.proj_spd_multiplier
        )

        imgui.Unindent()
    end


    -- limit to valid ranges
    if should_limit_to_valid_values then
        wnd_attribs.mana_max = math.max(wnd_attribs.mana_max, 0)
        wnd_attribs.mana_chrg_spd_secs = math.max(wnd_attribs.mana_chrg_spd_secs, 0)

        wnd_attribs.deck_capacity = math.max(wnd_attribs.deck_capacity, 1)
        wnd_attribs.spells_per_cast = math.max(wnd_attribs.spells_per_cast, 0)
    end




    -- Application of attributes
    if imgui.Button("Copy wand attributes") then
        wnd_attribs = WandAttribs.from_wand_entity(picked_wand_id)

        logger.info("Copied picked wand's attributes")
    end

    imgui.SameLine()
    if imgui.Button("Update on Wand") then
        wnd_attribs:apply_to(picked_wand_id)
        logger.info("updated picked wand")

        wand_utils.force_refresh_all_wands_on_player(picked_player_id)
        logger.info("refreshed wands for player")
    end

    imgui.SameLine()
    if imgui.Button("Spawn Wand at Player") then
        local x, y = EntityGetTransform(picked_player_id)

        local wand_id = wand_utils.spawn_default_wand_at(x, y)
        logger.info("Wand Spawned at player")

        wnd_attribs:apply_to(wand_id)
        logger.info("Wand attributes applied")
    end
end

function M.render_stat_presets(imgui, picked_player_id, picked_wand_id)
    local _

    imgui.Text("Save Category")
    imgui.SameLine()
    _, wand_stat_preset_save_category = imgui.InputText(
        "##SaveCategory", wand_stat_preset_save_category
    )

    wand_stat_preset_save_category = (wand_stat_preset_save_category:gsub(" ", ""))

    imgui.Text("Save Name")
    imgui.SameLine()
    _, wand_stat_preset_save_name = imgui.InputText(
        "##SaveName", wand_stat_preset_save_name
    )

    wand_stat_preset_save_name = (wand_stat_preset_save_name:gsub(" ", ""))

    local preset_exists = wand_stat_presets:has_value(
        wand_stat_preset_save_category,
        wand_stat_preset_save_name
    )

    local save_preset_clicked = false

    if preset_exists then
        save_preset_clicked = imgui_utils.cautious_button(imgui, "Override Preset")
    else
        save_preset_clicked = imgui_utils.green_button(imgui, "Save New Preset")
    end

    if save_preset_clicked then
        wand_stat_presets:set(
            wand_stat_preset_save_category,
            wand_stat_preset_save_name,

            wnd_attribs:serialize()
        )

        logger.info(
            ("Saved preset in category: '%s', with name: '%s'"):format(
                wand_stat_preset_save_category,
                wand_stat_preset_save_name
            )
        )

        wand_stat_presets_req_save = true

    end

    CategoryKVMapImgui.render(imgui, wand_stat_presets, {
        item_edit_action = function(ckv_map, cat_key, val_key)
            wnd_attribs = WandAttribs.load(
                ckv_map:get(cat_key, val_key)
            )

            logger.info(
                ("Editing wand attributes from category '%s' of name '%s'"):format(
                    cat_key, val_key
                )
            )
        end,

        on_item_moved = function(ckv_map, from_cat_key, from_val_key, to_cat_key, to_val_key)
            wand_stat_presets_req_save = true

            logger.info(
                ("Moved wand attributes preset from category '%s' of name '%s' to category '%s' of name '%s'"):format(
                    from_cat_key, from_val_key, to_cat_key, to_val_key
                )
            )
        end,

        
        on_item_duplicated = function(ckv_map, cat_key, val_key)
            ckv_map:duplicate(cat_key, val_key)

            wand_stat_presets_req_save = true

            logger.info(
                ("Duplicated wand attributes preset from category '%s' of name '%s'"):format(
                    cat_key, val_key
                )
            )
        end,

        on_item_deleted = function(ckv_map, cat_key, val_key)
            wand_stat_presets_req_save = true

            logger.info(
                ("Removed wand attribute preset from category '%s' of name '%s'"):format(
                    cat_key, val_key
                )
            )
        end,

        on_all_items_in_category_deleted = function(ckv_map, opened_cat_key)
            wand_stat_presets_req_save = true

            logger.info(
                ("Deleted all items in category '%s'"):format(
                    opened_cat_key
                )
            )
        end,

        on_entire_category_deleted = function(ckv_map, opened_cat_key)
            wand_stat_presets_req_save = true

            logger.info(
                ("Deleted the entire category '%s'"):format(
                    opened_cat_key
                )
            )
        end
    },
    function(imgui, ckv_map, cat_key, val_key)
        if picked_wand_id ~= nil and imgui_utils.green_button(imgui, "Update to held wand") then
            -- TODO: a merged duplicate with the load and edit above, maybe simplify this
            wnd_attribs = WandAttribs.load(
                ckv_map:get(cat_key, val_key)
            )

            logger.info(
                ("Loaded wand attributes from category '%s' of name '%s'"):format(
                    cat_key, val_key
                )
            )

            wnd_attribs:apply_to(picked_wand_id)
            logger.info("updated picked wand")

            wand_utils.force_refresh_all_wands_on_player(picked_player_id)
            logger.info("refreshed wands for player")
        end

        imgui.SameLine()
    end)
end


return M
