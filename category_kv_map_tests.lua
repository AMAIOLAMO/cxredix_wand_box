local CategoryKVMap = require("core.category_kv_map")

-- Load strict format data
local raw = [[
    Any:Test 'ABC, 1, 1; [G]: 1'
    Any:Love 'I, Love, Noita'
    
    Other:A 'ABC'
    Other:B 'BCD'
]]

local w = CategoryKVMap.load(raw)
assert(w:is_empty() == false)

local w_empty = CategoryKVMap.load("")
assert(w_empty:is_empty() == true)

assert(w:has_value("Any", "Test") == true)
assert(w:has_value("Any", "Love") == true)
assert(w:has_value("Other", "B") == true)
assert(w:has_value("Other", "A") == true)

assert(w:has_value("any", "Test") == false)
assert(w:has_value("Any", "test") == false)

assert(w:has_category("Any") == true)
assert(w:has_category("Other") == true)
assert(w:has_category("other") == false)
assert(w:has_category("any") == false)
assert(w:has_category("abc") == false)

assert(w:get("Any", "Test") == 'ABC, 1, 1; [G]: 1')
assert(w:get("Any", "Love") == 'I, Love, Noita')

assert(w:get("Other", "A") == 'ABC')
assert(w:get("Other", "B") == 'BCD')

assert(w:get("a", "b") == nil)

w:set("Any", "Cool", "SPELL_1, SPELL_2")

assert(w:has_value("Any", "Cool") and w:get("Any", "Cool") == "SPELL_1, SPELL_2")

w:set("New", "VeryNew", "ABC")

assert(w:has_value("New", "VeryNew") and w:get("New", "VeryNew") == "ABC")

w:remove_value("Any", "Cool")

assert(w:has_value("Any", "Cool") == false and w:get("Any", "Cool") == nil)

w:remove_value("New", "VeryNew")

assert(w:has_value("New", "VeryNew") == false and w:get("New", "VeryNew") == nil)
assert(w:has_category("New") == true)

w:remove_category("New")
assert(w:has_category("New") == false)


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
local w2 = CategoryKVMap.load(w:serialize())

local ws2_all = w2:get_all()

for k, cat in pairs(ws2_all) do
    for n, v in pairs(cat) do
        assert(w:get(k, n) == v)
    end
end


-- deleting entire section

w:remove_all_values_from_category("Any")

assert(w:has_value("Any", "Test") == false)
assert(w:has_value("Any", "Love") == false)

assert(w:has_value("Other", "B") == true)
assert(w:has_value("Other", "A") == true)

w:remove_all_values_from_category("Other")

assert(w:has_value("Other", "B") == false)
assert(w:has_value("Other", "A") == false)


-- moving from one category to the next

local w_move = CategoryKVMap.load(
    [[
        A:B 'test'
        C:G 'Another'
    ]]
)

assert(w_move:get("C", "G") == 'Another')

w_move:move_value_to(
    "C", "G",
    "A", "H"
)

assert(w_move:has_value("C", "G") == false)

assert(w_move:get("A", "H") == "Another")


-- override
assert(w_move:get("A", "B") == "test")

w_move:move_value_to(
    "A", "H",
    "A", "B"
)

assert(w_move:get("A", "B") == "Another")

-- duplicate

local w_dupe = CategoryKVMap.load(
    [[
        A:B 'dupe_this'
    ]]
)

local new_key_name = w_dupe:duplicate("A", "B")

assert(w_dupe:get("A", "B") == "dupe_this")

assert(w_dupe:get("A", new_key_name) == "dupe_this")


print("Complete")
