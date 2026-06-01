local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"

--- @module 'core.imgui_utils'
local imgui_utils = dofile_once(core_path .. "imgui_utils.lua")


--- @class core.category_kv_map_imgui
local M = {}

local delete_popup_msg = "__NO_MSG__ OH NO!"
local delete_popup_action = nil

function M.render(imgui, ckv_map, actions)
    local on_edit_proc      = actions.on_edit_proc or nil
    local on_move_proc      = actions.on_move_proc or nil
    local on_duplicate_proc = actions.on_duplicate_proc or nil

    local delete_item_popup_action = actions.delete_item_popup_action or nil

    local on_delete_all_items_in_category_action = actions.on_delete_all_items_in_category_action or nil
    local on_delete_entire_category_action = actions.on_delete_entire_category_action or nil


    if ckv_map:is_empty() then
        imgui.BulletText(
            "This is Empty :(, Save something to see them here!"
        )
    end

    local opened_category_tab_key = nil

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


    if imgui.CollapsingHeader("===[UNSAFE AREA]===") then
        if opened_category_tab_key and imgui_utils.cautious_button(imgui, "Delete All Items In Category") then
            ckv_map:remove_all_values_from_category(opened_category_tab_key)

            if on_delete_all_items_in_category_action then
                on_delete_all_items_in_category_action(ckv_map, opened_category_tab_key)
            end
        end

        imgui.SameLine()
        if opened_category_tab_key and imgui_utils.cautious_button(imgui, "Delete Entire Category") then
            ckv_map:remove_category(opened_category_tab_key)

            if on_delete_entire_category_action then
                on_delete_entire_category_action(ckv_map, opened_category_tab_key)
            end
        end
    end
end

return M
