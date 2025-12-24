-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 先给盐矿上tag ，还有进入列表
    local ALL_SALTSTACK_INST = {}
    AddPrefabPostInit("saltstack",function(inst)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddTag("tbat_tag.saltstack")
        ALL_SALTSTACK_INST[inst] = true
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim then
        return
    end
    if inst:HasTag("cave") then
        return
    end
    inst:DoTaskInTime(5+math.random(10),function()
        if inst.components.tbat_data:Get("building_reef_lighthouse_wild_spawned") then
            return
        end
        -----------------------------------------------------------------------------------------
            print("[TBAT][REEF-LIGHTHOUSE]开始寻找野外房子位置")
        -----------------------------------------------------------------------------------------
        --- 
            if next(ALL_SALTSTACK_INST) == nil then
                print("[TBAT][REEF-LIGHTHOUSE]没有找到盐矿")
                ALL_SALTSTACK_INST = nil
                return
            end
        -----------------------------------------------------------------------------------------
        -- 搜索参数
            local search_radius = 100
            local search_radius_sq = search_radius * search_radius
        -----------------------------------------------------------------------------------------
        --- 寻找距离平均位置最近的SalStack
            local function GetNearestCenterInst(ents)
                local total_x,total_z = 0,0
                local num = 0
                for k, tempInst in pairs(ents) do
                    if tempInst and tempInst:IsValid() then
                        local x,y,z = tempInst.Transform:GetWorldPosition()
                        total_x = total_x + x
                        total_z = total_z + z
                        num = num + 1
                    end
                end
                if num == 0 then
                    return nil
                end
                local avg_x,avg_z = total_x/num,total_z/num
                local nearest_ret = nil
                local nearest_dist_sq = search_radius_sq
                for k, tempInst in pairs(ents) do
                    if tempInst and tempInst:IsValid() then
                        local dis_sq = tempInst:GetDistanceSqToPoint(avg_x,0,avg_z)
                        if dis_sq < nearest_dist_sq then
                            nearest_ret = tempInst
                            nearest_dist_sq = dis_sq
                        end
                    end
                end
                return nearest_ret
            end
        -----------------------------------------------------------------------------------------
        ---
            local house_prefab = "tbat_building_reef_lighthouse_wild"
            local MAX_SPAWN_NUM = 3
            local current_num = 0
            for target_inst, _  in pairs(ALL_SALTSTACK_INST) do
                if target_inst and target_inst:IsValid() then
                    local x,y,z = target_inst.Transform:GetWorldPosition()
                    local ents = TheSim:FindEntities(x,0,z,search_radius, {house_prefab})
                    if #ents == 0 then
                        -- target_inst:Remove()
                        -- local house = SpawnPrefab(house_prefab)
                        -- house.Transform:SetPosition(x,0,z)
                        -- current_num = current_num + 1
                        -- print("[TBAT][REEF-LIGHTHOUSE]生成一个 ",house)
                        --- 寻找中心点目标
                        local center_inst = GetNearestCenterInst(TheSim:FindEntities(x,0,z,search_radius, {"tbat_tag.saltstack"})) or target_inst
                        local house_x,house_y,house_z = center_inst.Transform:GetWorldPosition()
                        local house = SpawnPrefab(house_prefab)
                        house.Transform:SetPosition(house_x,house_y,house_z)
                        current_num = current_num + 1
                        print("[TBAT][REEF-LIGHTHOUSE]生成一个 ",house)
                        center_inst:Remove()
                    end
                end
                if current_num >= MAX_SPAWN_NUM then
                    break
                end
            end
        -----------------------------------------------------------------------------------------
        ---
            if current_num >= MAX_SPAWN_NUM then
                print("[TBAT][REEF-LIGHTHOUSE]生成完毕")
                inst.components.tbat_data:Set("building_reef_lighthouse_wild_spawned",true)
            end
        -----------------------------------------------------------------------------------------
        --
            ALL_SALTSTACK_INST = nil
        -----------------------------------------------------------------------------------------
    end)
end)