AddPlayerPostInit(function(inst)
    if inst.prefab == "wolfgang" then return end

    inst:AddTag("mightiness_mighty")

    if not TheWorld.ismastersim then return end

    --背重物不减速
    if not inst.components.mightiness then
        inst:AddComponent("mightiness")
    end
    inst.components.mightiness.current = inst.components.mightiness.max
    inst.components.mightiness.state = "mighty"
    inst.components.mightiness.CanTransform = function() return false end
    inst.components.mightiness.GetPercent = function() return 1 end
    inst.components.mightiness.DoDelta = function() end
end)
