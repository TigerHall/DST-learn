local PICK_DROP_MULT = GetModConfigData("pick_drop_mult") --采集收获砍树挖矿
local ENT_DROP_MULT = GetModConfigData("ent_drop_mult")   --单位死亡掉落
local Utils = require("aab_utils/utils")

if PICK_DROP_MULT then
    local CANT_PICK_PREFABS = {
        gemsocket = true,
        moonbase = true,
        archive_switch = true
    }

    AddComponentPostInit("pickable", function(self)
        local OldPick = self.Pick
        self.Pick = function(self, ...)
            if CANT_PICK_PREFABS[self.inst.prefab] then
                return OldPick(self, ...)
            end

            local old_numtoharvest = self.numtoharvest
            self.numtoharvest = self.numtoharvest * PICK_DROP_MULT
            local res = { OldPick(self, ...) }
            self.numtoharvest = old_numtoharvest
            return unpack(res)
        end
    end)

    ----------------------------------------------------------------------------------------------------

    local function HarvestBefore(self)
        self.produce = self.produce * PICK_DROP_MULT --会在执行时帮我们重置为0
    end

    AddComponentPostInit("harvestable", function(self)
        Utils.FnDecorator(self, "Harvest", HarvestBefore)
    end)
end


----------------------------------------------------------------------------------------------------

local function GetMult(inst)
    if inst.is_oversized then
        return --不是巨大化作物
    end

    if ENT_DROP_MULT then
        if inst.components.health then
            return ENT_DROP_MULT --有生命的对象
        end
    end

    if PICK_DROP_MULT then
        local workable = inst.components.workable
        local act = workable and workable:GetWorkAction()
        if act and (inst:HasTag("tree") or (act == ACTIONS.CHOP or act == ACTIONS.MINE)) then
            return PICK_DROP_MULT --砍树凿矿
        end
    end
end

AddComponentPostInit("lootdropper", function(self)
    local OldGenerateLoot = self.GenerateLoot
    self.GenerateLoot = function(self, ...)
        local mult = GetMult(self.inst)
        if not mult then
            return OldGenerateLoot(self, ...)
        end

        local loots = {}

        for i = 1, mult do
            ConcatArrays(loots, OldGenerateLoot(self, ...))
        end

        self._aab_generatelooted = true
        self.inst:DoTaskInTime(0, function()
            self._aab_generatelooted = nil
        end)

        return loots
    end

    local OldSpawnLootPrefab = self.SpawnLootPrefab
    self.SpawnLootPrefab = function(self, ...)
        local mult = GetMult(self.inst)
        if self._aab_generatelooted or not mult then
            return OldSpawnLootPrefab(self, ...)
        end

        local loot
        for i = 1, mult do
            loot = OldSpawnLootPrefab(self, ...)
        end
        return loot
    end
end)

----------------------------------------------------------------------------------------------------
