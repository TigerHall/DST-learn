local Utils = require("aab_utils/utils")

local function UseBefore(self, num, ...)
    return nil, false, { self, 0, ... }
end

AddPrefabPostInit("saltlick", function(inst)
    if not TheWorld.ismastersim then return end
    Utils.FnDecorator(inst.components.finiteuses, "Use", UseBefore)
end)
