-- 虽然这几个值不改也没关系
TUNING.OASISLAKE_FISH_RESPAWN_TIME = 0
TUNING.FISH_RESPAWN_TIME = 0

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.fishable then
        inst.components.fishable:SetRespawnTime(0)
    end
end)
