dofile_once = function(str)
end

local WandAttribs = require("core.wand_attributes")

local wa = WandAttribs.load(
    "`ui_name` `item_name` true 26 false -1 5 3 100 50 50.3 3.0"
)

assert(wa.ui_name == "ui_name")
assert(wa.item_name == "item_name")
assert(wa.always_use_item_name_in_ui == true)
assert(wa.deck_capacity == 26)
assert(wa.should_shuffle == false)
assert(wa.cd_frames == -1)
assert(wa.rt_frames == 5)

assert(wa.spells_per_cast == 3)
assert(wa.mana_max == 100)
assert(wa.mana_chrg_spd_secs == 50)

assert(wa.spread_degrees == 50.3)

assert(wa.proj_spd_multiplier == 3.0)

-- round deserialize
local wa_round = WandAttribs.load(
    wa:serialize()
)

print(wa:serialize())

assert(wa.ui_name == "ui_name")
assert(wa.item_name == "item_name")
assert(wa.always_use_item_name_in_ui == true)
assert(wa.deck_capacity == 26)
assert(wa.should_shuffle == false)
assert(wa.cd_frames == -1)
assert(wa.rt_frames == 5)

assert(wa.spells_per_cast == 3)
assert(wa.mana_max == 100)
assert(wa.mana_chrg_spd_secs == 50)

assert(wa.spread_degrees == 50.3)

assert(wa.proj_spd_multiplier == 3.0)
