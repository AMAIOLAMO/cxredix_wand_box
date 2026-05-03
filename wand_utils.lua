dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")

dofile_once("mods/cxredix_wand_box/cx_actions_parser.lua")

function get_held_wand_id(player)
    local wands
    for _, child_id in ipairs(EntityGetAllChildren(player) or {}) do
        if EntityGetName(child_id) == "inventory_quick" then
            wands = EntityGetAllChildren(child_id, "wand")
        end
    end

    if wands == nil or #wands <= 0 then
        return nil
    end

    local sec_inv = EntityGetFirstComponent(player, "Inventory2Component")
    local active_item = ComponentGetValue2(sec_inv, "mActiveItem")

    for _, wand_id in ipairs(wands) do
        if wand_id == active_item then
            return wand_id
        end
    end

    return nil
end

function wand_clear_all_actions(wand_id)
    local child_ids = EntityGetAllChildren(wand_id, "card_action") or {}

    for _, child_id in ipairs(child_ids) do
        EntityRemoveFromParent(child_id)
        EntityKill(child_id)
    end
end

function wand_get_all_action_ids(wand_id)
    local child_ids = EntityGetAllChildren(wand_id, "card_action") or {}

    local action_ids = {}

    for _, child_id in ipairs(child_ids) do
        local action_comp = EntityGetFirstComponent(child_id, "ItemActionComponent")
        local action_id = ComponentGetValue2(action_comp, "action_id")

        table.insert(action_ids, action_id)
    end

    return action_ids
end


function wand_is_action_count_greater_than(wand_id, threshold)
    local children = EntityGetAllChildren(wand_id, "card_action") or {}

    local count = 0

    for _, child_id in ipairs(children) do
        count = count + 1

        if count > threshold then
            return true
        end
    end

    return false
end


function wand_set_deck_cap(wand_id, cap)
    local ability = EntityGetFirstComponentIncludingDisabled( wand_id, "AbilityComponent" )

    if ability then
        ComponentObjectSetValue2( ability, "gun_config", "deck_capacity", cap)
    else
        GamePrint("Error, ability component not found!")
    end
end

function all_wand_force_refresh(player)
    local sec_inv = EntityGetFirstComponent(player, "Inventory2Component")

    if sec_inv == nil then
        return
    end
    -- else

    ComponentSetValue2(sec_inv, "mForceRefresh", true)
    ComponentSetValue2(sec_inv, "mActualActiveItem", 0)
    ComponentSetValue2(sec_inv, "mDontLogNextItemEquip", true)
end

-- loads a new action to the specified index (index starts at 1)
function wand_create_action_id_at(wand_id, action_id, idx)
    local action_entity = CreateItemActionEntity(action_id, 0, 0)
    EntityAddChild(wand_id, action_entity)

    local item_comp = EntityGetFirstComponentIncludingDisabled(action_entity, "ItemComponent")
    local _, item_y_pos = ComponentGetValue2(item_comp, "inventory_slot")
    -- zeroth it out idx - 1
    ComponentSetValue2(item_comp, "inventory_slot", idx - 1, item_y_pos)

    EntitySetComponentsWithTagEnabled(action_entity, "enabled_in_world", false)
end

function wand_append_action_str(wand_id, raw_str)
    local action_ids = cx_parse_wndbx_fmt_to_action_ids(raw_str)

    for idx, action_id in ipairs(action_ids) do
        if action_id == nil or action_id == '' then
            goto continue
        end
            
        wand_create_action_id_at(wand_id, action_id, idx)

        -- This does not work, tha game seems to load the particle emitter differently.
        -- local particle_emitter = EntityGetFirstComponentIncludingDisabled(action_entity, "ParticleEmitterComponent")
        -- EntityRemoveComponent(action_entity, particle_emitter)

        ::continue::
    end

    wand_set_deck_cap(wand_id, #action_ids)
    return #action_ids
end

function wand_has_action(wand_id)
    return wand_is_action_count_greater_than(wand_id, 0)
end
