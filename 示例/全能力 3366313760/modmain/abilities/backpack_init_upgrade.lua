AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.container
        and inst.components.equippable
        -- and inst.components.equippable.equipslot == EQUIPSLOTS.BODY 可能会有多格mod改掉
        and inst.components.inventoryitem
    then
        inst.components.container:EnableInfiniteStackSize(true)
    end
end)


