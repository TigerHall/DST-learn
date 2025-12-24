local Utils = require("aab_utils/utils")

AddGamePostInit(function()
    AAB_ReplaceCharacterLines("wanda")
end)

Utils.FnDecorator(ACTIONS.CAST_POCKETWATCH, "fn", function(act)
    local doer = act.doer
    if doer and not doer.components.oldager and act.invobject and act.invobject.prefab == "pocketwatch_heal" then
        --不老表
        local health = doer.components.health
        if health ~= nil and not health:IsDead() then
            health:DoDelta(TUNING.POCKETWATCH_HEAL_HEALING, true, act.invobject)
            local fx = SpawnPrefab((doer.components.rider ~= nil and doer.components.rider:IsRiding()) and "pocketwatch_heal_fx_mount" or "pocketwatch_heal_fx")
            fx.entity:SetParent(doer.entity)
            act.invobject.components.rechargeable:Discharge(TUNING.POCKETWATCH_HEAL_COOLDOWN)
            return true
        end

        return { true }, true
    end
end)

local function Init(inst)
    inst.components.positionalwarp:SetMarker("pocketwatch_warp_marker")
end

AddPlayerPostInit(function(inst)
    if inst.prefab == "wanda" then return end

    inst:AddTag("clockmaker")
    inst:AddTag("pocketwatchcaster")

    if not TheWorld.ismastersim then return end

    if not inst.components.positionalwarp then
        inst:AddComponent("positionalwarp")
    end

    inst:DoTaskInTime(0, Init)

    inst.components.positionalwarp:SetWarpBackDist(TUNING.WANDA_WARP_DIST_NORMAL)
end)
