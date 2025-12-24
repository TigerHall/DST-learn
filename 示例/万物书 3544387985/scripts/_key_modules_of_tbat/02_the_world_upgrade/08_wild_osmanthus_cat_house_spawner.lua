-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    墓地范围内刷3个

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local task = function(inst)
    if inst.components.tbat_data:Get("wild_osmanthus_cat_house_spawned") then
        return
    end
    inst.components.tbat_data:Set("wild_osmanthus_cat_house_spawned",true)

    local graveyard_mid_pt = TBAT.FNS:GetGraveyardLocation()
    if graveyard_mid_pt == nil then
        return
    end
    print("野生桂花猫猫房子开始创建")
    print("寻找到墓地中点",graveyard_mid_pt)
    local all_poinst = {}
    local radius = 40
    local delta_radius = 7
    local min_raidus = 7
    local available_points = {}
    local recipe = AllRecipes["tbat_building_osmanthus_cat_pet_house"]
    while radius > min_raidus do
        local poinst = TBAT.FNS:GetSurroundPoints({
            target = graveyard_mid_pt,
            range = radius,
            num = radius*4
        })
        for k, temp_pt in pairs(poinst) do
            if TheWorld.Map:CanDeployRecipeAtPoint(temp_pt,recipe) and TBAT.MAP:HasTagInPoint(temp_pt.x,0,temp_pt.z,"Mist") then
                table.insert(available_points,temp_pt)
            end
        end
        radius = radius - delta_radius
    end
    print("可放置墓地地皮数量",#available_points)
    if #available_points > 0 then
        local ret_poinsts = TBAT.FNS:GetRandomDiffrenceValuesFromTable(available_points,3)
        for k, temp_pt in pairs(ret_poinsts) do
            local house = SpawnPrefab("tbat_building_osmanthus_cat_pet_house_wild")
            house.Transform:SetPosition(temp_pt.x,temp_pt.y,temp_pt.z)
            print("已生成野生桂花猫猫房子",k,house)
        end
    end


end

AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(5,task)
end)