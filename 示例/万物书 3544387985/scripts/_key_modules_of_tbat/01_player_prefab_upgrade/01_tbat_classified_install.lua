-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    所有玩家都拥有的模块

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if inst.tbat_classified == nil then
        local tbat_classified = SpawnPrefab("tbat_classified")
        inst.tbat_classified = tbat_classified
        tbat_classified:Init(inst)
    end
    -- if TBAT.DEBUGGING then
    --     inst:AddComponent("tbat_com_excample_classified")
    --     inst:DoPeriodicTask(0.2,function()
    --         inst.components.tbat_com_excample_classified:SetNum(math.random(100000)/100)
    --     end)
    -- end
    
end)
