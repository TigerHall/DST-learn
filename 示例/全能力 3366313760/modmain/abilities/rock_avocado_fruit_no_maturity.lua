AddPrefabPostInit("rock_avocado_bush", function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.growable:StopGrowing()
    table.remove(inst.components.growable.stages, 4) --我直接把第四阶段删了，会不会有兼容问题呢
    inst.components.growable:SetStage(math.random(1, 3))
    inst.components.growable:StartGrowing()
end)
