local Utils = require("aab_utils/utils")

local function OnTransplantAfter(retTab, self)
    self.transplanted = false --移植标记，对于其他mod直接修改值不管
    return retTab
end

AddComponentPostInit("pickable", function(self)
    Utils.FnDecorator(self, "OnTransplant", nil, OnTransplantAfter)
end)

----------------------------------------------------------------------------------------------------
-- 把地图上已有的植物的移植标记也去掉，用于中途添加功能的玩家
local function Init(inst)
    if inst.components.pickable then
        inst.components.pickable.transplanted = false
    end
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    inst:DoTaskInTime(0, Init)
end)
