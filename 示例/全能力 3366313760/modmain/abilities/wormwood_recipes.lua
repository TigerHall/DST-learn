-- 有些组件和方法没加，希望不要因为技能树导致崩溃了，好在科雷是判断有没有组件了
AAB_ActivateSkills("wormwood")

----------------------------------------------------------------------------------------------------

-- Also called from skilltree_wormwood.lua
local function UpdatePhotosynthesisState(inst, isday)
    local should_photosynthesize = false
    if isday and inst.fullbloom and inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wormwood_blooming_photosynthesis") and not inst:HasTag("playerghost") then
        should_photosynthesize = true
    end
    if should_photosynthesize ~= inst.photosynthesizing then
        inst.photosynthesizing = should_photosynthesize
        if inst.components.health then
            if should_photosynthesize then
                local regen = TUNING.WORMWOOD_PHOTOSYNTHESIS_HEALTH_REGEN
                inst.components.health:AddRegenSource(inst, regen.amount, regen.period, "photosynthesis_skill")
            else
                inst.components.health:RemoveRegenSource(inst, "photosynthesis_skill")
            end
        end
    end
end

----------------------------------------------------------------------------------------------------


AddPlayerPostInit(function(inst)
    if inst.prefab == "wormwood" then return end
    inst:AddTag("plantkin")

    if not TheWorld.ismastersim then return end

    inst.UpdatePhotosynthesisState = inst.UpdatePhotosynthesisState or UpdatePhotosynthesisState

    local bloomness = inst:AddComponent("bloomness") --占个位不报错就行
    bloomness:SetDurations(TUNING.WORMWOOD_BLOOM_STAGE_DURATION, TUNING.WORMWOOD_BLOOM_FULL_DURATION)
    inst.components.bloomness.onlevelchangedfn = function() end
end)
