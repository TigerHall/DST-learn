AddPrefabPostInit("chester", function(inst)
    if not TheWorld.ismastersim then return end
    RemovePhysicsColliders(inst)
end)
AddPrefabPostInit("hutch", function(inst)
    if not TheWorld.ismastersim then return end
    RemovePhysicsColliders(inst)
end)