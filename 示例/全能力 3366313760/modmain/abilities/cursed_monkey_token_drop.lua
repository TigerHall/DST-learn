local Utils = require("aab_utils/utils")

--- 可以丢弃诅咒饰品
local function GivenBefore(self, item, data)
    return nil, data.owner and data.owner:HasTag("player")
end

AddComponentPostInit("curseditem", function(self)
    Utils.FnDecorator(self, "Given", GivenBefore)
end)

----------------------------------------------------------------------------------------------------

local function IsCursableBefore()
    return { false }, true
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    Utils.FnDecorator(inst.components.cursable, "IsCursable", IsCursableBefore) --不会被诅咒饰品吸引
end)
