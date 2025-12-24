local PAUSE_REASON =
{
    TILE = "WRONG_TILE",
    SEASON = "WRONG_SEASON",
}

-- 源代码拷贝，移除地皮和季节的判断
local function Sapling_CheckGrowConstraints(inst)
    inst.components.growable:Resume(PAUSE_REASON.TILE)
    inst.components.growable:Resume(PAUSE_REASON.SEASON)
end

local function Full_CanRegenFruits(inst)
    return true
end

for _, v in ipairs({
    "ancienttree_nightvision_sapling",
    "ancienttree_nightvision",

    "ancienttree_gem_sapling",
    "ancienttree_gem"
}) do
    AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end

        if inst.CheckGrowConstraints then
            inst:StopWatchingWorldState("season", inst.CheckGrowConstraints)

            inst.CheckGrowConstraints = Sapling_CheckGrowConstraints
            inst:WatchWorldState("season", inst.CheckGrowConstraints)
            inst:DoTaskInTime(0.1, inst.CheckGrowConstraints) --覆盖掉科雷对growable的操作
        end

        if inst.CanRegenFruits then
            inst.CanRegenFruits = Full_CanRegenFruits
        end
    end)
end
