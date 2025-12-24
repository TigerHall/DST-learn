AddPrefabPostInit("multitool_axe_pickaxe", function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.tool:SetAction(ACTIONS.DIG, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:SetAction(ACTIONS.HAMMER, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
end)
