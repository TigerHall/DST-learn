local ATTACK_HEAL = GetModConfigData("attack_heal") / 100

local function OnHitOther(inst, data)
    if data and data.damage and data.damage > 0 then
        inst.components.health:DoDelta(data.damage * ATTACK_HEAL, true, "debug_key") --兼容旺达
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("onhitother", OnHitOther)
end)
