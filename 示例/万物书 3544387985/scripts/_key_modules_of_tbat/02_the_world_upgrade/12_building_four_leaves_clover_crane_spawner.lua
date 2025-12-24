-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim then
        return
    end
    if TheWorld:HasTag("cave") then
        return
    end
    inst:DoTaskInTime(1,function()
        if inst.components.tbat_data:Get("tbat_building_four_leaves_clover_crane_lv1") then
            return
        end
        local moonbase = TheSim:FindFirstEntityWithTag("moonbase")
        if moonbase == nil then
            return
        end
        local temp_wall_item = SpawnPrefab("wall_stone_item")

        local pt = TBAT.FNS:GetRandomSurroundPoint({
            target = moonbase,
            max_radius = 20,
            min_raidus = 10,
            delta_raidus = 0.3,
            num_mult = 3,  -- 密度倍数
            test = function(pt)
                return TheWorld.Map:CanDeployWallAtPoint(pt,temp_wall_item)
            end,
        })
        temp_wall_item:Remove()
        if pt then
            inst.components.tbat_data:Set("tbat_building_four_leaves_clover_crane_lv1",true)
            SpawnPrefab("tbat_building_four_leaves_clover_crane_lv1").Transform:SetPosition(pt.x,pt.y,pt.z)
            print("[TBAT]成功生成野外四叶草鹤雕像")
        else
            print("[TBAT][ERROR]生成野外四叶草鹤雕像失败！！")
        end

    end)
end)