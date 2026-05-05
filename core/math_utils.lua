--- @class math_utils
local M = {}

-- linear interpolation between a and b
function M.lerpf(a, b, t)
    return a + (b - a) * t
end

-- clamps an integer value v between min_val and max_val
function M.clampi(v, min_val, max_val)
    assert(
        min_val <= max_val,
        string.format(
            "minimum value %d cannot be bigger than maximum value %d", min_val, max_val
        )
    )
    return math.max(math.min(v, max_val), min_val)
end

-- rounds a value to it's nearest integer
function M.round(v)
    return math.floor(v + 0.5) + 1
end

return M
