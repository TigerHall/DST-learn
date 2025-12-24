AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.equippable
        and (inst.components.fueled or inst.components.armor or inst.components.perishable or inst.components.finiteuses)
        and not inst:HasTag("medal") --排除能力勋章的勋章
    then
        inst:AddComponent("aab_finiteuses_heal")
    end
end)
