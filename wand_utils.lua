dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")

dofile_once("mods/cxredix_wand_box/cx_actions_parser.lua")

local cx_deck_sync = dofile_once("mods/cxredix_wand_box/cx_deck_sync.lua")

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

function force_refresh_all_wands_on_player(player_id)
    local sec_inv = EntityGetFirstComponent(player_id, "Inventory2Component")

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

function held_wand_deck_direct_sync(player_id, actions_str)
    assert(player_id ~= nil, "Must sync with a non nil player id")

    local held_wand_id = get_held_wand_id(player_id)

    assert(held_wand_id ~= nil, "Cannot directly sync when there is no held wand")

    -- we need to add 1 dummy spell if the wand is empty,
    -- this is due to the fact that if the wand has 0 card actions
    -- as entities in the game, refreshing the wand will not happen.

    wand_clear_all_actions(held_wand_id)
    wand_append_action_str(held_wand_id, "MANA_REDUCE")

    cx_deck_sync.set_sync_actions(actions_str)

    force_refresh_all_wands_on_player(player_id)
end
