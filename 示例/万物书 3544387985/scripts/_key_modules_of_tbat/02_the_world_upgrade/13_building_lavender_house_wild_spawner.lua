-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



AddPrefabPostInit("moon_fissure",function(inst)
    inst:AddTag("tbat_tag.moon_fissure")
end)
AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim then
        return
    end
    if inst:HasTag("cave") then
        return
    end
    inst:DoTaskInTime(5+math.random(10),function()
        if inst.components.tbat_data:Get("building_lavender_house_wild_spawned") then
            return
        end
        -----------------------------------------------------------------------------------------
        print("[TBAT][LAVENDER-KITTY]开始寻找野外房子位置")
        -----------------------------------------------------------------------------------------
        --- 符合条件的地皮得拥有全部tag
            local tags = {"RoadPoison","moonhunt","nohasslers","lunacyarea","not_mainland"}
            local function tags_fix(temp_index_tags)
                for k, tag in pairs(tags) do
                    if temp_index_tags[tag] == nil then
                        return false
                    end
                end
                return true
            end
        -----------------------------------------------------------------------------------------
            local moon_fissure = TheSim:FindFirstEntityWithTag("tbat_tag.moon_fissure")
            if moon_fissure == nil then
                print("[TBAT][LAVENDER-KITTY][ERROR]没找到月岛上的标志实体")
                return
            end
        -----------------------------------------------------------------------------------------
        --- 寻找位置
            local temp_wall_item = SpawnPrefab("wall_stone_item")
            local test_fn = function(pt)
                local _,temp_index_tags = TBAT.MAP:GetAllTagsInPoint(pt.x,pt.y,pt.z)
                if tags_fix(temp_index_tags)
                    and TheWorld.Map:IsAboveGroundAtPoint(pt.x,pt.y,pt.z)
                    and TheWorld.Map:CanDeployWallAtPoint(pt,temp_wall_item)
                    and TheWorld.Map:CanDeployWallAtPoint(Vector3(pt.x+2,0,pt.z+2),temp_wall_item)
                    and TheWorld.Map:CanDeployWallAtPoint(Vector3(pt.x-2,0,pt.z+2),temp_wall_item)
                    and TheWorld.Map:CanDeployWallAtPoint(Vector3(pt.x+2,0,pt.z-2),temp_wall_item)
                    and TheWorld.Map:CanDeployWallAtPoint(Vector3(pt.x-2,0,pt.z-2),temp_wall_item)
                    then
                    -- local ents = TheSim:FindEntities(pt.x,pt.y,pt.z,50,{"tbat_tag.moon_fissure"})
                    -- if #ents > 0 then
                    --     return true
                    -- end
                    return true
                end
                return false
            end
            local ret,all_avalable_points = TBAT.FNS:GetRandomSurroundPoint({
                target = moon_fissure,
                max_radius = 50,
                min_raidus = 0,
                delta_raidus = 2,
                test = test_fn,
                -- num_mult = 10,
            })
            temp_wall_item:Remove()
        -----------------------------------------------------------------------------------------
        ---
            if ret == nil or #all_avalable_points < 2 then
                print("[TBAT][LAVENDER-KITTY][ERROR]没找到合适的位置")
                return
            end
        -----------------------------------------------------------------------------------------
        --- 寻找2个位置
            local points = TBAT.FNS:GetRandomDiffrenceValuesFromTable(all_avalable_points, 2)
            for k, pt in pairs(points) do
                SpawnPrefab("tbat_building_lavender_flower_house_wild_lv1").Transform:SetPosition(pt.x,pt.y,pt.z)
                inst.components.tbat_data:Set("building_lavender_house_wild_spawned",true)
                print("[TBAT][LAVENDER-KITTY]野外的薰衣草花房已生成",pt)
            end
        -----------------------------------------------------------------------------------------
        ---
            -- inst.components.tbat_data:Set("building_lavender_house_wild_spawned",true)
            -- print("[TBAT][LAVENDER-KITTY]野外的薰衣草花房已生成")
        -----------------------------------------------------------------------------------------

    end)
end)