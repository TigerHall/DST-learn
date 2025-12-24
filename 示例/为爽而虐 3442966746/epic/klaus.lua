local attackspeedup = GetModConfigData("extra_change") and GetModConfigData("boss_attackspeed") or 1
-- 克劳斯加强，无视海陆墙
-- TUNING.KLAUS_HEALTH_REZ = 1
--攻速加快
if attackspeedup < 1.33 then TUNING.KLAUS_ATTACK_PERIOD = TUNING.KLAUS_ATTACK_PERIOD * 3 / 4 * attackspeedup end

local scale = TUNING.KLAUS_ENRAGE_SCALE * TUNING.KLAUS_ENRAGE_SCALE * TUNING.KLAUS_ENRAGE_SCALE
local absorption = 1 - 1 / scale
--持续掉血
local function enragecost(inst)
    if inst.enraged and not inst.components.health:IsDead() then inst.components.health:DoDelta(-TUNING.KLAUS_HEALTH_REGEN, false, "oldager_component") end
end

local function resetAbsorptionAmount(inst)
    if inst.components.commander then
        local soldiers = inst.components.commander:GetNumSoldiers()
        inst.components.health:SetAbsorptionAmount(absorption * (2 - soldiers) / 2)
    else
        inst.components.health:SetAbsorptionAmount(absorption)
    end
    if inst.enraged and not inst.mod_hardmode_enragecosttask then inst.mod_hardmode_enragecosttask = inst:DoPeriodicTask(1, enragecost) end
end

-- local function enragetrugger(inst)
--     if not inst.enraged and inst:IsUnchained() and not inst.components.health:IsDead() then
--         inst:PushEvent("enrage")
--         resetAbsorptionAmount(inst)
--     end
-- end

AddPrefabPostInit("klaus", function(inst)
    if not TheWorld.ismastersim then return end
    local oldEnrage = inst.Enrage
    inst.Enrage = function(inst, ...)
        oldEnrage(inst, ...)
        ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .03, 1, inst, 40)
        resetAbsorptionAmount(inst)
        if not inst.mod_hardmode_enragecosttask then inst.mod_hardmode_enragecosttask = inst:DoPeriodicTask(1, enragecost) end
    end
    inst:ListenForEvent("soldierschanged", resetAbsorptionAmount)
    inst:DoTaskInTime(0.25, resetAbsorptionAmount)
    -- inst.components.healthtrigger:AddTrigger(0.50031, enragetrugger)
end)
--开包狂暴
-- AddPrefabPostInit("klaus_sack", function(inst)
--     if not TheWorld.ismastersim then return end
--     local onusekeyfn = inst.components.klaussacklock.onusekeyfn
--     inst.components.klaussacklock:SetOnUseKey(function(inst, key, doer, ...)
--         if key.components.klaussackkey == nil then
--         elseif key.components.klaussackkey.truekey then
--         else
--             if inst.components.entitytracker:GetEntity("klaus") ~= nil then
--                 local klaus = inst.components.entitytracker:GetEntity("klaus")
--                 if not klaus.enraged and not klaus.components.health:IsDead() then
--                     klaus:PushEvent("enrage")
--                     resetAbsorptionAmount(klaus)
--                 end
--             end
--         end
--         return onusekeyfn(inst, key, doer, ...)
--     end)
-- end)
