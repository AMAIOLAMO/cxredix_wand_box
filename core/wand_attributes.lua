local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local libs_path = root_path .. "libs/"

--- @module 'core.wand_utils'
local uwand = dofile_once(core_path .. "wand_utils.lua")

--- @class core.wand_attributes
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

function M.load(str)
    local res = M.new_default()

    local ui_name, item_name, always_use_item_name_in_ui, deck_capacity,
        should_shuffle, cd_frames, rt_frames, spells_per_cast,
        mana_max, mana_chrg_spd_secs, spread_degrees, proj_spd_multiplier = str:match(
            "`([^`]*)` `([^`]*)` ([^%s]+) ([^%s]+) ([^%s]+) ([^%s]+) ([^%s]+) ([^%s]+) ([^%s]+) ([^%s]+) ([^%s]+) ([^%s]+)"
        )

    -- TODO: this strictly has to sync with serialization, a change in structure
    -- or order breaks this
    
    res.ui_name                    = ui_name
    res.item_name                  = item_name
    res.always_use_item_name_in_ui = always_use_item_name_in_ui == "true"
    res.deck_capacity              = tonumber(deck_capacity)

    res.should_shuffle             = should_shuffle == "true"

    res.cd_frames                  = tonumber(cd_frames)
    res.rt_frames                  = tonumber(rt_frames)
    res.spells_per_cast            = tonumber(spells_per_cast)
    res.mana_max                   = tonumber(mana_max)
    res.mana_chrg_spd_secs         = tonumber(mana_chrg_spd_secs)
    res.spread_degrees             = tonumber(spread_degrees)
    res.proj_spd_multiplier        = tonumber(proj_spd_multiplier)

    return res
end

function M:serialize()
    local fields = {
        self.ui_name,
        self.item_name,
        self.always_use_item_name_in_ui,
        self.deck_capacity,
        self.should_shuffle,
        self.cd_frames,
        self.rt_frames,
        self.spells_per_cast,
        self.mana_max,
        self.mana_chrg_spd_secs,
        self.spread_degrees,
        self.proj_spd_multiplier
    }
    
    local parts = {}
    for i, val in ipairs(fields) do
        if type(val) == "string" then
            table.insert(parts, "`" .. val .. "`")
        else
            table.insert(parts, tostring(val))
        end
    end
    return table.concat(parts, " ")
end

return M
