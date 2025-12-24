-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --[[

    

-- ]]--
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local check_index = "building_forest_mushroom_cottage_wild_spawned"

local main_search_fn = function(inst)
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ---
        if inst.components.tbat_data:Get(check_index) then
            return
        end
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ---    
        print("[TBAT][SNAIL]野生蘑菇小蜗房子创建任务开始")
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    --- 寻找月台
        local moonbase = TheSim:FindFirstEntityWithTag("moonbase")
        if moonbase == nil then
            print("[TBAT][SNAIL]没有找到月台,任务退出")
            return
        end
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    --- 寻找合适区域。需要创建的区域为半径20。 中心点距离月台 40+10 。获取周围一圈的 地皮中心点（注意处理重复）
        local search_radius = 40 + 10
        local points = TBAT.FNS:GetSurroundPoints({
            target = moonbase,
            range = search_radius,
            num = math.floor(2*3*search_radius/3),
        })
        local temp_check_points = {}
        for k, pt in pairs(points) do
            local tile_center_point = Vector3(TBAT.MAP:GetTileCenterPoint(pt.x,0,pt.z))
            local temp_index = "tile"..tile_center_point.x.."_"..tile_center_point.z
            temp_check_points[temp_index] = tile_center_point
        end
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    --- 先确定区域符合，避免超出地图 。 
        local tile_lengh = 4 -- 一个地皮格子单边长度
        local left_top_offset = Vector3(-2*tile_lengh , 0 ,-3*tile_lengh)
        local right_bottom_offset = Vector3( 3*tile_lengh, 0 ,3*tile_lengh)
        local area_available_centers = {}
        local map_w,map_h = TheWorld.Map:GetSize()
        local function is_point_out_of_map(pt)
            local tile_x,tile_y = TBAT.MAP:GetTileXYByWorldPoint(pt.x,0,pt.z)
            if tile_x < 0 or tile_y < 0 or tile_x > map_w or tile_y > map_h then
                return true
            end
            return false
        end
        for k, tile_center_point in pairs(temp_check_points) do
            local left_top_pt = tile_center_point + left_top_offset
            local right_bottom_pt = tile_center_point + right_bottom_offset
            if not is_point_out_of_map(left_top_pt) and not is_point_out_of_map(right_bottom_pt) then
                table.insert(area_available_centers,tile_center_point)
            end
        end
        print("[TBAT][SNAIL]找到可能合适区域数量",#area_available_centers)
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    --- 创建区域检查，不能替换官方的区域(半径20)
        print("[TBAT][SNAIL]区域内部检查开始")
        local area_building_checked_points = {}
        local area_tags = {"structure","wall","irreplaceable","nonpotatable","nosteal","antlion_sinkhole_blocker","event_trigger"}
        local function can_use_this_area(pt)
            local ents = TheSim:FindEntities(pt.x,0,pt.z,20,nil,nil,area_tags)
            if #ents > 0 then
                -- print("++++++++++++++++++++++++++++++++++++++++++")
                -- print("[TBAT][SNAIL]区域内部检:")
                -- for k,v in pairs(ents) do
                --     print(v:GetDebugString())
                -- end
                -- print("++++++++++++++++++++++++++++++++++++++++++")
                return false
            end
            return true
        end
        for k, tile_center_point in pairs(area_available_centers) do
            if can_use_this_area(tile_center_point) then
                table.insert(area_building_checked_points,tile_center_point)
            end
        end
        if #area_building_checked_points == 0 then
            print("[TBAT][SNAIL]没有找到合适的区域,任务退出。等待下次存档创建。")
            return
        end
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    --- 得到最后锚点区域                
        local ret_pt = area_building_checked_points[math.random(#area_building_checked_points)]
        local distance = moonbase:GetDistanceSqToPoint(ret_pt.x,0,ret_pt.z)^0.5
        print("[TBAT][SNAIL]最终锚点区域",ret_pt,distance)
        print("[TBAT][SNAIL]野生蘑菇小蜗房子创建位置搜索任务完成，开始执行区域内部生成。")
        SpawnPrefab("tbat_room_wild_mushroom_snail_house_area_spawner").Transform:SetPosition(ret_pt.x,0,ret_pt.z)
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ---
        inst.components.tbat_data:Set(check_index,true)
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

end

AddPrefabPostInit("world",function(inst)
    if TheWorld:HasTag("cave") then
        return
    end
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(10 + math.random(20),main_search_fn)
end)