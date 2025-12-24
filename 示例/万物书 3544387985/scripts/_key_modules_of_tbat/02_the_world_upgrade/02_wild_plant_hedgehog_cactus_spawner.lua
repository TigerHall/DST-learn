-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPrefabPostInit("oasislake",function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(0,function()
        if TheWorld.components.tbat_data:Get("wild_hedgehog_cactus_spawned") then
            return
        end
        TheWorld.components.tbat_data:Set("wild_hedgehog_cactus_spawned",true)
        local max_num = 3
        local current_num = 0
        local radius = 16
        local min_radius = 6
        
        local test_plant = SpawnPrefab("tbat_plant_wild_hedgehog_cactus")
        while radius > min_radius do
            local points = TBAT.FNS:GetSurroundPoints({
                target = inst,
                range = radius,
                num = radius*5
            })
            local pt = points[math.random(1,#points)]
            if TheWorld.Map:CanDeployAtPoint(pt,inst) then
                SpawnPrefab("tbat_plant_wild_hedgehog_cactus").Transform:SetPosition(pt.x,0,pt.z)
                current_num = current_num + 1
            end            
            radius = radius - 3
            if current_num >= max_num then
                break
            end
        end
        test_plant:Remove()
    end)
end)