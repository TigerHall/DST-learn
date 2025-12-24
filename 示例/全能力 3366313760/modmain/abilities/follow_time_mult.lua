local Utils = require("aab_utils/utils")
local FOLLOW_TIME_MULT = GetModConfigData("follow_time_mult") / 100

local function AddLoyaltyTimeBefore(self, time, ...)
    return nil, false, { self, time * FOLLOW_TIME_MULT, ... }
end

AddComponentPostInit("follower", function(self)
    Utils.FnDecorator(self, "AddLoyaltyTime", AddLoyaltyTimeBefore)
end)
