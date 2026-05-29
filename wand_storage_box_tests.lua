local WandStorageBox = require("core.wand_storage_box")

-- Load strict format data
local raw = [[
    Any:Test 'ABC, 1, 1; [G]: 1'
    Any:Love 'I, Love, Noita'
]]
local w = WandStorageBox.load(raw)

assert(w:has_value("Any", "Test") == true)

assert(w:has_value("any", "Test") == false)
assert(w:has_value("Any", "test") == false)

assert(w:has_category("Any") == true)
assert(w:has_category("any") == false)
assert(w:has_category("abc") == false)

assert(w:get("Any", "Test") == 'ABC, 1, 1; [G]: 1')
assert(w:get("a", "b") == nil)

w:set("Any", "Cool", "SPELL_1, SPELL_2")

assert(w:has_value("Any", "Cool") and w:get("Any", "Cool") == "SPELL_1, SPELL_2")

w:remove("Any", "Cool")

assert(w:has_value("Any", "Cool") == false and w:get("Any", "Cool") == nil)

-- Get all data from ONE category
local ct_data = w:get_all_from_category("Any")

assert(ct_data["Test"] == 'ABC, 1, 1; [G]: 1')
assert(ct_data["Love"] == 'I, Love, Noita')

-- Get ALL categories + ALL data
local all_data = w:get_all()

for ct_key, ct in pairs(all_data) do
    for k, v in pairs(ct) do
        assert(w:has_value(ct_key, k) == true and w:get(ct_key, k) == v)
    end
end

-- Round Trip serialization & loading :)
local w2 = WandStorageBox.load(w:serialize())

local ws2_all = w2:get_all()

for k, cat in pairs(ws2_all) do
    for n, v in pairs(cat) do
        assert(w:get(k, n) == v)
    end
end

print("Complete")
