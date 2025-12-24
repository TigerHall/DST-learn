AddPrefabPostInit("phonograph", function(inst)
    if not TheWorld.ismastersim then return inst end

    inst.TurnOffMachine = function() end --为什么科雷设计成播放64秒就停止了？
end)
