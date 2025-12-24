AddPrefabPostInit("bernie_inactive", function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.equippable.restrictedtag = nil
end)

AddPlayerPostInit(function(inst)
    inst:AddTag("bernieowner")
    inst:AddTag("pyromaniac")
end)
