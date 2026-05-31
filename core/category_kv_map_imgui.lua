local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"

--- @module 'core.imgui_utils'
local imgui_utils = dofile_once(core_path .. "imgui_utils.lua")


--- @class core.category_kv_map_imgui
local M = {}

local delete_popup_msg = "__NO_MSG__ OH NO!"
local delete_popup_action = nil

function M.render(imgui, ckv_map, actions)
    local req_save = false

    local on_edit_proc             = actions.on_edit_proc or nil
    local on_duplicate_proc        = actions.on_duplicate_proc or nil
    local delete_item_popup_action = actions.delete_item_popup_action or nil
    -- local _
    --
    -- imgui.Text("Save Category")
    -- imgui.SameLine()
    -- _, storage_box_save_category = imgui.InputText(
    --     "##SaveCategory", storage_box_save_category
    -- )
    --
    -- imgui.Text("Save Name")
    -- imgui.SameLine()
    -- _, storage_box_save_name = imgui.InputText(
    --     "##SaveName", storage_box_save_name
    -- )
    --
    -- if imgui.Button("Save to Storage Box") then
    --     wand_storage_box:set(
    --         storage_box_save_category, storage_box_save_name,
    --         loader_state.actions_str
    --     )
    --
    --     req_save_storage_box = true
    --
    --     logger.info(
    --         "Save complete"
    --     )
    -- end
    --
    -- imgui.Separator()
    --
    if ckv_map:is_empty() then
        imgui.BulletText(
            "This is Empty :(, Save something to see them here!"
        )

        return req_save
    end

    -- Render Category KV Map
    if imgui.BeginTabBar("CategoryKVMap") then
        local storage_all = ckv_map:get_all()

        for cat_key, cat in pairs(storage_all) do
            imgui.PushID("##" .. cat_key)

            if imgui.BeginTabItem(string.format("%s", cat_key)) then
                local tbl_flags = bit.bor(
                    imgui.TableFlags.Resizable,
                    imgui.TableFlags.Hideable,
                    imgui.TableFlags.RowBg
                )

                local col_count = 2

                opened_category_tab_key = cat_key

                if imgui.BeginTable("##Table_" .. cat_key, col_count, tbl_flags) then
                    imgui.TableSetupColumn("Name")
                    imgui.TableSetupColumn("Action", imgui.TableColumnFlags.WidthFixed)
                    imgui.TableHeadersRow()

                    for val_key, val_str in pairs(cat) do
                        imgui.PushID("##" .. val_key)

                        -- Name Column
                        imgui.TableNextColumn()
                        imgui.BulletText(val_key)

                        -- Action Column
                        imgui.TableNextColumn()

                        if imgui.SmallButton("Edit") then
                            if on_edit_proc ~= nil then
                                on_edit_proc(ckv_map, cat_key, val_key)
                            end
                        end

                        imgui.SameLine()
                        if imgui.SmallButton("Duplicate") then
                            if on_duplicate_proc ~= nil then
                                on_duplicate_proc(ckv_map, cat_key, val_key)
                            end
                        end

                        imgui.SameLine()
                        if imgui.SmallButton("Move") then
                            if on_move_proc ~= nil then
                                on_move_proc(ckv_map, cat_key, val_key)
                            end
                        end

                        imgui.SameLine()
                        if imgui_utils.cautious_button(imgui, "-") then
                            delete_popup_msg = "Do you really want to delete this item?"
                            delete_popup_action = delete_item_popup_action

                            imgui.OpenPopup("delete_confirm_popup")
                        end


                        if imgui.BeginPopup("delete_confirm_popup") then
                            imgui.Text(delete_popup_msg)

                            imgui.Text("Click anywhere else to cancel")

                            if imgui.Button("Yes") then

                                if delete_popup_action ~= nil then
                                    delete_popup_action(ckv_map, cat_key, val_key)
                                end

                            end

                            imgui.EndPopup()
                        end

                        imgui.PopID()
                    end

                    imgui.EndTable()
                end


                imgui.EndTabItem()
            end

            imgui.PopID()
        end

        imgui.EndTabBar()
    end

    -- if opened_category_tab_key and imgui_cautious_btn(imgui, "Delete All Items In Category") then
    --     ckv_map:remove_all_values_from_category(opened_category_tab_key)
    --
    --     req_save_storage_box = true
    --
    --     logger.info(
    --         ("Removed all items from category '%s'"):format(opened_category_tab_key)
    --     )
    -- end
    --
    -- imgui.SameLine()
    -- if opened_category_tab_key and imgui_cautious_btn(imgui, "Delete Entire Category") then
    --     ckv_map:remove_category(opened_category_tab_key)
    --
    --     req_save_storage_box = true
    --
    --     logger.info(
    --         ("Removed category '%s'"):format(opened_category_tab_key)
    --     )
    -- end

    return req_save
end

return M
