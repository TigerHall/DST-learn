AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.container
        and inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.BODY
        and inst.components.inventoryitem
    then
        inst.components.inventoryitem.cangoincontainer = true
    end
end)

-- 背包虽然可以放到物品栏里，但是右键还是“装备”，要不要加个新的ACTION为打开，让打开优先级高于装备呢？
