dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")

local ProfileTimer = {}
ProfileTimer.__index = ProfileTimer

-- Example usage:
--
-- local ProfileTimer = require("ProfileTimer")
-- local my_timer = ProfileTimer.new()
--
-- my_timer.begin_append()
--
-- Run your thing
--
-- my_timer.end_append()
--
--
-- Other non relevant stuff
--
--
-- my_timer.begin_append()
--
-- Resumption of your other thing
--
-- my_timer.end_append()
--
--
--
-- print("it took a total of: " . tostring(my_timer.get_total_secs()) .. " seconds.")

function ProfileTimer.new()
    local obj = setmetatable(
        {rec_begin_time_secs = 0, total_rec_time_secs = 0},
        ProfileTimer
    )

    return obj
end

function ProfileTimer:begin_append()
    self.rec_begin_time_secs = GameGetRealWorldTimeSinceStarted()
end

function ProfileTimer:end_append()
    self.total_rec_time_secs = self.total_rec_time_secs + (
        GameGetRealWorldTimeSinceStarted() - self.rec_begin_time_secs
    )

    return self.total_rec_time_secs
end

function ProfileTimer:get_total_secs()
    return self.total_rec_time_secs
end

function ProfileTimer:clear()
    self.total_rec_time_secs = 0
    self.rec_begin_time_secs = 0
end

return ProfileTimer
