local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"

--- @module 'core.wand_utils'
local uwand = dofile_once(core_path .. "wand_utils.lua")

--- @class WandAttributes
local M = {
    -- placed here to make lsp happy
    ui_name = "Wand",
    item_name = "Wand",
    always_use_item_name_in_ui = true,

    deck_capacity = 26,
    should_shuffle = false,

    cd_frames = 10,
    rt_frames = 10,

    spells_per_cast = 1,

    mana_max = 100,
    mana_chrg_spd_secs = 100,

    spread_degrees = 0.0,
    proj_spd_multiplier = 1.0
}
M.__index = M

-- creates a new wand attributes and populates default values
function M.new_default()
    -- TODO: does not account for Always Cast spells
    return setmetatable({
        ui_name = "Wand",
        item_name = "",
        always_use_item_name_in_ui = false,

        deck_capacity = 26,
        should_shuffle = false,

        cd_frames = 10,
        rt_frames = 10,

        spells_per_cast = 1,

        mana_max = 100,
        mana_chrg_spd_secs = 100,

        spread_degrees = 0,
        proj_spd_multiplier = 1
    }, M)
end

function M.from_wand_entity(wand_id)
    local wand_attrs = M.new_default()

    -- TODO: ui name and item name should be separated
    wand_attrs.ui_name = uwand.wand_get_name(wand_id)
    wand_attrs.item_name = uwand.wand_get_name(wand_id)

    wand_attrs.always_use_item_name_in_ui = uwand.wand_get_always_use_item_name_in_ui(wand_id)

    wand_attrs.deck_capacity = uwand.wand_get_deck_cap(wand_id)
    wand_attrs.should_shuffle = uwand.wand_get_should_shuffle(wand_id)

    wand_attrs.cd_frames = uwand.wand_get_cast_delay_frames(wand_id)
    wand_attrs.rt_frames = uwand.wand_get_recharge_time_frames(wand_id)

    wand_attrs.spells_per_cast = uwand.wand_get_spells_per_cast(wand_id)

    wand_attrs.mana_max = uwand.wand_get_mana_max(wand_id)
    wand_attrs.mana_chrg_spd_secs = uwand.wand_get_mana_charge_speed(wand_id)

    wand_attrs.spread_degrees = uwand.wand_get_spread_degrees(wand_id)
    wand_attrs.proj_spd_multiplier = uwand.wand_get_projectile_speed_multiplier(wand_id)

    return wand_attrs
end

function M:apply_to(wand_id)
    -- TODO: ui name and item name should be separated
    uwand.wand_set_name(wand_id, self.item_name)

    uwand.wand_set_always_use_item_name_in_ui(wand_id, self.always_use_item_name_in_ui)

    uwand.wand_set_deck_cap(wand_id, self.deck_capacity)
    uwand.wand_set_should_shuffle(wand_id, self.should_shuffle)

    uwand.wand_set_cast_delay_frames(wand_id, self.cd_frames)
    uwand.wand_set_recharge_time_frames(wand_id, self.rt_frames)

    uwand.wand_set_spells_per_cast(wand_id, self.spells_per_cast)

    uwand.wand_set_mana_max(wand_id, self.mana_max)
    uwand.wand_set_mana_charge_speed(wand_id, self.mana_chrg_spd_secs)

    uwand.wand_set_spread_degrees(wand_id, self.spread_degrees)
    uwand.wand_set_projectile_speed_multiplier(wand_id, self.proj_spd_multiplier)
end

return M
