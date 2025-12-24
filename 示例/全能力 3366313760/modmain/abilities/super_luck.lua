AddPrefabPostInit("lucy", function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.tool:SetAction(ACTIONS.DIG, 1)
    inst.components.tool:SetAction(ACTIONS.MINE, 2)
end)
