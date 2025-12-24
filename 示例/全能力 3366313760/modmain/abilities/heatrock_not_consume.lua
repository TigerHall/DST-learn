local Utils = require("aab_utils/utils")

local function DoDeltaBefore(self, amount)
    return nil, amount and amount < 0
end

AddPrefabPostInit("heatrock", function(inst)
    if not TheWorld.ismastersim then return end
    Utils.FnDecorator(inst.components.fueled, "DoDelta", DoDeltaBefore)
end)
