-- 三叉戟无法攻击飞行单位
AddPrefabPostInit("trident", function(inst)
    if not TheWorld.ismastersim then return end
    local _DoWaterExplosionEffect = inst.DoWaterExplosionEffect
    inst.DoWaterExplosionEffect = function(inst, v, ...)
        if v and v:IsValid() and (v:HasTag("flying") or v:HasTag("swc2hm") or (v.components.health and v:IsOnValidGround())) then return end
        _DoWaterExplosionEffect(inst, v, ...)
    end
end)
AddStategraphPostInit("wilson", function(sg)
    local chop = sg.states.chop.onenter
    sg.states.chop.onenter = function(inst, ...)
        chop(inst, ...)
        inst.sg.statemem.recoilstate = "gnaw_recoil"
    end
    local dig = sg.states.dig.onenter
    sg.states.dig.onenter = function(inst, ...)
        dig(inst, ...)
        inst.sg.statemem.recoilstate = "gnaw_recoil"
    end
end)
