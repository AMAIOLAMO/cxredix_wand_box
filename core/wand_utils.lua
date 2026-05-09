dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")

local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"

--- @module 'cx_action_parse_utils'
local cx_parser = dofile_once(core_path .. "cx_action_parse_utils.lua")

--- @module 'cx_deck_sync'
local cx_deck_sync = dofile_once(core_path .. "cx_deck_sync.lua")

--- @class wand_utils
local M = {}

function M.get_held_wand_id(player)
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

function M.wand_clear_all_actions(wand_id)
    local child_ids = EntityGetAllChildren(wand_id, "card_action") or {}

    for _, child_id in ipairs(child_ids) do
        EntityRemoveFromParent(child_id)
        EntityKill(child_id)
    end
end

function M.wand_get_all_action_ids(wand_id)
    local child_ids = EntityGetAllChildren(wand_id, "card_action") or {}

    local action_ids = {}

    for _, child_id in ipairs(child_ids) do
        local action_comp = EntityGetFirstComponentIncludingDisabled(child_id, "ItemActionComponent")
        local action_id = ComponentGetValue2(action_comp, "action_id")

        table.insert(action_ids, action_id)
    end

    return action_ids
end

function M.wand_get_all_actions_as_actions_str(wand_id)
    local action_ids = M.wand_get_all_action_ids(wand_id)

    local actions_str = ""

    for i, action_id in ipairs(action_ids) do
        actions_str = actions_str .. action_id

        if i ~= #action_ids then
            actions_str = actions_str .. ","
        end
    end

    return actions_str
end


function M.wand_is_action_count_greater_than(wand_id, threshold)
    local children = EntityGetAllChildren(wand_id, "card_action") or {}

    local count = 0

    for _, _ in ipairs(children) do
        count = count + 1

        if count > threshold then
            return true
        end
    end

    return false
end


function M.force_refresh_all_wands_on_player(player_id)
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
function M.wand_create_action_id_at(wand_id, action_id, idx)
    local action_entity = CreateItemActionEntity(action_id, 0, 0)
    EntityAddChild(wand_id, action_entity)

    local item_comp = EntityGetFirstComponentIncludingDisabled(action_entity, "ItemComponent")
    local _, item_y_pos = ComponentGetValue2(item_comp, "inventory_slot")

    -- since nolla assumed index start with zero here
    ComponentSetValue2(item_comp, "inventory_slot", idx - 1, item_y_pos)

    EntitySetComponentsWithTagEnabled(action_entity, "enabled_in_world", false)
end

function M.wand_append_action_str(wand_id, raw_str, adapt_deck_size)
    local action_ids = cx_parser.parse_to_action_ids(raw_str)

    for idx, action_id in ipairs(action_ids) do
        if action_id == nil or action_id == '' then
            goto continue
        end

        M.wand_create_action_id_at(wand_id, action_id, idx)

        -- This does not work, tha game seems to load the particle emitter differently.
        -- local particle_emitter = EntityGetFirstComponentIncludingDisabled(action_entity, "ParticleEmitterComponent")
        -- EntityRemoveComponent(action_entity, particle_emitter)

        ::continue::
    end

    if adapt_deck_size then
        M.wand_set_deck_cap(wand_id, #action_ids)
    end

    return #action_ids
end

function M.wand_has_action(wand_id)
    return M.wand_is_action_count_greater_than(wand_id, 0)
end

function M.held_wand_deck_direct_sync(player_id, actions_str)
    assert(player_id ~= nil, "Must sync with a non nil player id")

    local held_wand_id = M.get_held_wand_id(player_id)

    assert(held_wand_id ~= nil, "Cannot directly sync when there is no held wand")

    -- we need to add 1 dummy spell if the wand is empty,
    -- this is due to the fact that if the wand has 0 card actions
    -- as entities in the game, refreshing the wand will not happen.

    M.wand_clear_all_actions(held_wand_id)
    M.wand_append_action_str(held_wand_id, "MANA_REDUCE", true)

    cx_deck_sync.set_sync_actions(actions_str)

    M.force_refresh_all_wands_on_player(player_id)
end

function M.spawn_default_wand_at(x, y)
    local wand_id = EntityLoad(root_path .. "vendor/entities/default_wand.xml", x, y)

    return wand_id
end

-- wand ability component -- 
function M.wand_get_ability_asserted(wand_id)
    local comp = EntityGetFirstComponentIncludingDisabled(wand_id, "AbilityComponent")
    assert(
        comp ~= nil,
        "Cannot find ability component on the given wand entity: " .. tostring(wand_id)
    )
    return comp
end

function M.wand_ability_set_field_asserted(wand_id, field_name, value)
    local comp = M.wand_get_ability_asserted(wand_id)

    ComponentSetValue2(comp, field_name, value)
end

function M.wand_ability_gun_action_cfg_set_field_asserted(wand_id, field_name, value)
    local comp = M.wand_get_ability_asserted(wand_id)

    ComponentObjectSetValue2(comp, "gunaction_config", field_name, value)
end

function M.wand_ability_gun_cfg_set_field_asserted(wand_id, field_name, value)
    local comp = M.wand_get_ability_asserted(wand_id)

    ComponentObjectSetValue2(comp, "gun_config", field_name, value)
end


-- item component --

function M.wand_get_item(wand_id)
    return EntityGetFirstComponentIncludingDisabled(wand_id, "ItemComponent")
end

function M.wand_get_item_asserted(wand_id)
    local comp = M.wand_get_item(wand_id)
    assert(
        comp ~= nil,
        "Cannot find item component on the given wand entity: " .. tostring(wand_id)
    )
    return comp
end

function M.wand_item_set_field_asserted(wand_id, field, value)
    local comp = M.wand_get_item_asserted(wand_id)

    SetComponentValue2(comp, field, value)
end


-- wand attributes --
function M.wand_set_name(wand_id, value)
    local ability_comp = M.wand_get_ability_asserted(wand_id)
    local item_comp = M.wand_get_item_asserted(wand_id)

    ComponentSetValue2(ability_comp, "ui_name", value)
    ComponentSetValue2(item_comp, "item_name", value)
end

function M.wand_set_always_use_item_name_in_ui(wand_id, value)
    local item_comp = M.wand_get_item_asserted(wand_id)
    ComponentSetValue2(item_comp, "always_use_item_name_in_ui", value)
end

function M.wand_set_deck_cap(wand_id, value)
    M.wand_ability_gun_cfg_set_field_asserted(wand_id, "deck_capacity", value)
end

function M.wand_set_mana_max(wand_id, value)
    M.wand_ability_set_field_asserted(wand_id, "mana_max", value)
end

function M.wand_set_mana_charge_speed(wand_id, value)
    M.wand_ability_set_field_asserted(wand_id, "mana_charge_speed", value)
end

function M.wand_set_mana(wand_id, value)
    M.wand_ability_set_field_asserted(wand_id, "mana", value)
end

function M.wand_set_cast_delay_frames(wand_id, value)
    M.wand_ability_gun_action_cfg_set_field_asserted(wand_id, "fire_rate_wait", value)
end

function M.wand_set_recharge_time_frames(wand_id, value)
    M.wand_ability_gun_cfg_set_field_asserted(wand_id, "reload_time", value)
end

function M.wand_set_spread_degrees(wand_id, value)
    M.wand_ability_gun_action_cfg_set_field_asserted(wand_id, "spread_degrees", value)
end

function M.wand_set_spells_per_cast(wand_id, value)
    M.wand_ability_gun_cfg_set_field_asserted(wand_id, "actions_per_round", value)
end

function M.wand_set_should_shuffle(wand_id, value)
    M.wand_ability_gun_cfg_set_field_asserted(wand_id, "shuffle_deck_when_empty", value)
end


function M.wand_set_should_shuffle(wand_id, value)
    M.wand_ability_gun_cfg_set_field_asserted(wand_id, "shuffle_deck_when_empty", value)
end

function M.wand_set_projectile_speed_multiplier(wand_id, value)
    M.wand_ability_gun_action_cfg_set_field_asserted(wand_id, "speed_multiplier", value)
end

return M
