local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"

--- @module 'core.imgui_utils'
local imgui_utils = dofile_once(core_path .. "imgui_utils.lua")


--- @class core.category_kv_map_imgui
local M = {
    actions = {}
}
M.__index = M

local target_move_category = "Any"
local target_move_name = "__NAME__"


function M.render(imgui, ckv_map, actions)

    -- TODO: inconsistent usecase, except the edit_proc, we should let the others be simply just
    -- a finished callback

    local item_edit_action = actions.item_edit_action or nil

    local on_item_moved      = actions.on_item_moved or nil
    local on_item_duplicated = actions.on_item_duplicated or nil

    local on_item_deleted = actions.on_item_deleted or nil

    local on_all_items_in_category_deleted = actions.on_all_items_in_category_deleted or nil
    local on_entire_category_deleted       = actions.on_entire_category_deleted or nil


    if ckv_map:is_empty() then
        imgui.BulletText(
            "This is Empty :(, Save something to see them here!"
        )

        return
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
                            if item_edit_action ~= nil then
                                item_edit_action(ckv_map, cat_key, val_key)
                            end
                        end

                        imgui.SameLine()
                        if imgui.SmallButton("Duplicate") then
                            if on_item_duplicated ~= nil then
                                on_item_duplicated(ckv_map, cat_key, val_key)
                            end
                        end

                        imgui.SameLine()
                        if imgui.SmallButton("Move") then
                            target_move_name = val_key

                            imgui.OpenPopup("move_item_popup")
                        end

                        if imgui.BeginPopup("move_item_popup") then
                            local _
                            _, target_move_category = imgui.InputText(
                                "Target Category", target_move_category
                            )
                            
                            _, target_move_name = imgui.InputText(
                                "Target Name", target_move_name
                            )

                            if imgui.Button("Move") then
                                ckv_map:move_value_to(
                                    cat_key, val_key, target_move_category, target_move_name
                                )

                                if on_item_moved then
                                    on_item_moved(
                                        ckv_map,
                                        cat_key, val_key,
                                        target_move_category, target_move_name
                                    )
                                end
                            end

                            imgui.EndPopup()
                        end

                        imgui.SameLine()
                        if imgui_utils.cautious_button(imgui, "-") then
                            imgui.OpenPopup("delete_confirm_popup")
                        end


                        if imgui.BeginPopup("delete_confirm_popup") then
                            imgui.Text("Do you really want to delete this item?")
                            imgui.Text("Click anywhere else to cancel")

                            if imgui_utils.cautious_small_button(imgui, "Yes") then
                                ckv_map:remove_value(cat_key, val_key)

                                if on_item_deleted ~= nil then
                                    on_item_deleted(ckv_map, cat_key, val_key)
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
            imgui.OpenPopup("delete_all_items_in_category_confirm_popup")
        end

        if imgui.BeginPopup("delete_all_items_in_category_confirm_popup") then
            imgui.Text(
                ("Are you sure you want to delete all the items within the category '%s'?"):format(
                    opened_category_tab_key
                )
            )

            imgui.Text("Click anywhere else to Cancel")

            if imgui_utils.cautious_small_button(imgui, "Yes") then
                ckv_map:remove_all_values_from_category(opened_category_tab_key)

                if on_all_items_in_category_deleted then
                    on_all_items_in_category_deleted(ckv_map, opened_category_tab_key)
                end
            end

            imgui.EndPopup()
        end
            

        imgui.SameLine()
        if opened_category_tab_key and imgui_utils.cautious_button(imgui, "Delete Entire Category") then
            imgui.OpenPopup("delete_entire_category_confirm_popup")
        end


        if imgui.BeginPopup("delete_entire_category_confirm_popup") then
            imgui.Text(
                ("Are you sure you want to delete the entire category '%s'?"):format(
                    opened_category_tab_key
                )
            )

            imgui.Text("Click anywhere else to Cancel")

            if imgui_utils.cautious_small_button(imgui, "Yes") then
                ckv_map:remove_category(opened_category_tab_key)

                if on_entire_category_deleted then
                    on_entire_category_deleted(ckv_map, opened_category_tab_key)
                end
            end

            imgui.EndPopup()
        end


    end
end

return M
