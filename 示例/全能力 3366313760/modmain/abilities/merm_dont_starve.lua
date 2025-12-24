AddPrefabPostInit("mermking", function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.hunger.burnratemodifiers:SetModifier(inst, 0, "aab_merm_dont_starve")
end)
