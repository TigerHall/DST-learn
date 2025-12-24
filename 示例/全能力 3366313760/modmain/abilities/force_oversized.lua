AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if inst:HasTag("plantedsoil") and inst:HasTag("farm_plant") and inst:HasTag("plant") then
        inst.force_oversized = true
    end
end)
