-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local task = function(inst)
    
    local tempInst = CreateEntity()
    tempInst.entity:SetParent(inst.entity)
    TheWorld.components.tbat_com_hunter_repliacer:AddReplacerFn(tempInst,function(tempInst,origin_prefab)
        if TheWorld.state.iswinter and math.random() < 0.8 and not TheWorld.state.isday or TBAT.DEBUGGING then
            return "tbat_animal_snow_plum_chieftain"
        end
        return origin_prefab
    end)

end

AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(5,task)


end)