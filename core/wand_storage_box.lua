--- @module "core.wand_storage_box"
local M = {}
M.__index = M

-- speed up
local string_gmatch = string.gmatch
local string_format = string.format
local table_concat = table.concat
local pairs, setmetatable, assert, type = pairs, setmetatable, assert, type

-- format -> Category:Key 'Value'
local fmt_pattern = "([%w_][%w%-_]*):([%w_][%w%-_]*)%s*'([^']*)'"

function M.load(raw_strs)
    assert(type(raw_strs) == "string", "Input must be a string")
    local obj = { category_kv_map = {} }

    for cat_key, val_key, val_str in string_gmatch(raw_strs, fmt_pattern) do
        -- cool way to initialize to {} if nil
        obj.category_kv_map[cat_key] = obj.category_kv_map[cat_key] or {}
        obj.category_kv_map[cat_key][val_key] = val_str
    end

    return setmetatable(obj, M)
end

function M.load_from_globals(globals_key)
    return M.load(GlobalsGetValue(globals_key, ""))
end

function M:is_empty()
    for _k, _v in pairs(self:get_all()) do
        return false
    end

    return true
end

function M:get(category, key)
    assert(type(category) == "string", "Category is required to be a string")
    assert(type(key) == "string", "Key is required to be a string")

    local cat_tbl = self.category_kv_map[category]
    return cat_tbl and cat_tbl[key] or nil
end

function M:set(category, key, value)
    assert(type(category) == "string", "Category is required to be a string")
    assert(type(key) == "string", "Key is required to be a string")
    assert(type(value) == "string", "Value is required to be a string")

    self.category_kv_map[category] = self.category_kv_map[category] or {}
    self.category_kv_map[category][key] = value
end

function M:has_category(category)
    return self.category_kv_map[category] ~= nil
end

function M:remove_category(category)
    if self:has_category(category) then
        self.category_kv_map[category] = nil
    end
end

function M:has_value(category, key)
    return self:get(category, key) ~= nil
end

function M:remove_value(category, key)
    if self:has_value(category, key) then
        self.category_kv_map[category][key] = nil
    end
end

function M:remove_all_values_from_category(category)
    if self:has_category(category) then
        local cat = self:get_all_from_category(category)

        for val_key, _ in pairs(cat) do
            self:remove_value(category, val_key)
        end
    end
end

function M:get_all_from_category(category)
    assert(type(category) == "string", "Category is required")
    return self.category_kv_map[category] or {}
end

function M:get_all()
    return self.category_kv_map
end

function M:serialize()
    local lines = {}

    for cat_key, cat in pairs(self.category_kv_map) do
        for val_key, val_str in pairs(cat) do
            lines[#lines + 1] = string_format(
                "%s:%s '%s'", cat_key, val_key, val_str
            )
        end
    end

    return table_concat(lines, "\n")
end

function M:save_to_globals(globals_key)
    GlobalsSetValue(globals_key, self:serialize())
end

return M
