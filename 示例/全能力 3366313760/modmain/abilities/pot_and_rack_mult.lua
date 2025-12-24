local POT_AND_RACK_MULT = GetModConfigData("pot_and_rack_mult") --采集收获砍树挖矿
local Utils = require("aab_utils/utils")

--让多倍采集也适用于锅
local function HarvestBefore(self, harvester)
    if not self.done
        or not harvester
        or not harvester:HasTag("player")
        or not self.product
    then
        return
    end

    for i = 1, POT_AND_RACK_MULT - 1 do --少收获一个，剩下一个交给原有代码处理
        local loot = SpawnPrefab(self.product)
        if loot then
            harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
        end
    end
end

AddComponentPostInit("stewer", function(self)
    Utils.FnDecorator(self, "Harvest", HarvestBefore)
end)

----------------------------------------------------------------------------------------------------
-- 适用于晾肉架
local function HarvestBefore2(self, harvester)
    if not self:IsDone()
        or not harvester
        or not harvester:HasTag("player")
        or not self.product
    then
        return
    end

    for i = 1, POT_AND_RACK_MULT - 1 do --少收获一个，剩下一个交给原有代码处理
        local loot = SpawnPrefab(self.product)
        if loot then
            harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
        end
    end
end

AddComponentPostInit("dryer", function(self)
    Utils.FnDecorator(self, "Harvest", HarvestBefore2)
end)
