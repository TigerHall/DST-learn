AddPrefabPostInit("firesuppressor", function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.fueled.rate_modifiers:SetModifier(inst, 0, "aab_firesuppressor_not_consume")
end)
