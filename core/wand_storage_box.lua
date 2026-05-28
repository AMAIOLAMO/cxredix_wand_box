--- @module "core.wand_storage_box"
local WandStorageBox = {}
WandStorageBox.__index = WandStorageBox

-- speed up
local string_gmatch = string.gmatch
local string_format = string.format
local table_concat = table.concat
local pairs, setmetatable, assert, type = pairs, setmetatable, assert, type

-- format -> Category:Key 'Value'
local fmt_pattern = "([%w_][%w%-_]*):([%w_][%w%-_]*)%s*'([^']*)'"

function WandStorageBox.load(raw_strs)
    assert(type(raw_strs) == "string", "Input must be a string")
    local obj = { category_kv_map = {} }

    for cat, key, val in string_gmatch(raw_strs, fmt_pattern) do
        obj.category_kv_map[cat] = obj.category_kv_map[cat] or {}
        obj.category_kv_map[cat][key] = val
    end

    return setmetatable(obj, WandStorageBox)
end

function WandStorageBox:get(category, key)
    assert(type(category) == "string", "Category is required")
    assert(type(key) == "string", "Key is required")

    local cat_tbl = self.category_kv_map[category]
    return cat_tbl and cat_tbl[key] or nil
end

function WandStorageBox:set(category, key, value)
    assert(type(category) == "string", "Category is required")
    assert(type(key) == "string", "Key is required")
    self.category_kv_map[category] = self.category_kv_map[category] or {}
    self.category_kv_map[category][key] = tostring(value or "")
end

function WandStorageBox:has(category, key)
    return self:get(category, key) ~= nil
end

function WandStorageBox:remove(category, key)
    local cat_tbl = self.category_kv_map[category]
    if cat_tbl then cat_tbl[key] = nil end
end

function WandStorageBox:get_all_from_category(category)
    assert(type(category) == "string", "Category is required")
    return self.category_kv_map[category] or {}
end

function WandStorageBox:get_all()
    return self.category_kv_map
end

function WandStorageBox:serialize()
    local lines = {}
    for cat, cat_tbl in pairs(self.category_kv_map) do
        for key, val in pairs(cat_tbl) do
            lines[#lines + 1] = string_format("%s:%s '%s'", cat, key, val)
        end
    end
    return table_concat(lines, "\n")
end

return WandStorageBox
