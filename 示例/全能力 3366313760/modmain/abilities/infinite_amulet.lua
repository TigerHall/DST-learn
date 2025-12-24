local AMULETS = {
    amulet = true,
    blueamulet = true,
    purpleamulet = true,
    orangeamulet = true,
    greenamulet = true,
    yellowamulet = true,
}

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if AMULETS[inst.prefab]
        or (inst.components.equippable and EQUIPSLOTS.NECK and inst.components.equippable.equipslot == EQUIPSLOTS.NECK)
    then
        if inst.components.finiteuses then
            inst.components.finiteuses.Use = function() end
        end

        if inst.components.fueled then
            inst.components.fueled.rate_modifiers:SetModifier(inst, 0, "aab_infinite_amulet")
        end
    end
end)
