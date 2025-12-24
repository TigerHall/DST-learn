-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    TBAT.MAP:CreateBlock(name,tile_start_x,tile_start_y)

    TheWorld.Map:GetTileAtPoint(x,y,z)



]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- a 区域
    TBAT.MAP:AddBlock("fantasy_island_block_c",function(start_x,start_y)
        -----------------------------------------------------------------------------------
        ---
            print("幻想岛屿区域 _c 开始创建")
            local start_time = os.clock()
        -----------------------------------------------------------------------------------
        ---
            local width,height = 11,14
            local AA = WORLD_TILES["OCEAN_COASTAL"]
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("turf_savanna")
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("DIRT")
            local BB = WORLD_TILES[string.upper("tbat_turf_fallen_cherry_blossoms")]
            -- local CC = TBAT.MAP:GetTileIndexByItemPrefab("DIRT")
            local CC = WORLD_TILES[string.upper("cotl_brick")]
            local data = {
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,BB,BB,AA,BB,BB,AA,AA,AA,
                AA,AA,BB,CC,CC,BB,CC,CC,BB,AA,AA,
                AA,BB,BB,CC,CC,BB,CC,CC,BB,BB,AA,
                BB,CC,CC,BB,BB,BB,BB,BB,CC,CC,BB,
                BB,CC,CC,BB,CC,CC,CC,BB,CC,CC,BB,
                BB,BB,BB,CC,CC,CC,CC,CC,BB,BB,BB,
                AA,BB,CC,CC,CC,CC,CC,CC,CC,BB,AA,
                AA,BB,CC,CC,CC,CC,CC,CC,CC,BB,AA,
                AA,BB,BB,CC,CC,BB,CC,CC,BB,BB,AA,
                AA,AA,BB,BB,BB,AA,BB,BB,BB,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA
            }
        -----------------------------------------------------------------------------------
        --- 设置地皮
            local index = 1
            for y = start_y,start_y+height-1 do 
                for x = start_x,start_x+width-1 do
                    local tile = data[index]
                    index = index + 1
                    TheWorld.Map:SetTile(x,y,tile)
                end
            end
        -----------------------------------------------------------------------------------
        --- 码头
            local dock_offsets = {
                {11,12},
            }
            for k, offsets in pairs(dock_offsets) do
                local tile_x = start_x + offsets[1] - 1
                local tile_y = start_y + offsets[2] - 1
                -- TheWorld.Map:SetTile(tile_x,tile_y,WORLD_TILES["MONKEY_DOCK"])
                TheWorld.components.dockmanager:CreateDockAtTile(tile_x,tile_y, WORLD_TILES.MONKEY_DOCK)
            end
        -----------------------------------------------------------------------------------
        --- 设置锚点
            local start_pt = TBAT.MAP:GetWorldPointByTileXY(start_x,start_y)
            local offset_x = TILE_SCALE * 5
            local offset_y = TILE_SCALE * 8
            -- SpawnPrefab("tbat_room_anchor_fantasy_island_c").Transform:SetPosition(start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            TBAT.MAP:CreateUniqueAnchor("tbat_room_anchor_fantasy_island_c",start_pt.x+offset_x , 0 , start_pt.z+offset_y)
        -----------------------------------------------------------------------------------
        ---
            local end_time = os.clock()
            local cost_time = end_time - start_time
            print(string.format("幻想岛屿区域 _c 创建耗时 : %.4f 秒", cost_time))
        -----------------------------------------------------------------------------------    
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 装修（debug）
    -- if TBAT.DEBUGGING then
    --     TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_c","debug_pighouse",function(x,y,z)
    --         SpawnPrefab("pighouse").Transform:SetPosition(x,y,z)
    --     end)
    -- end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_c","level_1",function(x,y,z)
        local data = '{"rock1":{"prefab":"rock1","points":[{"z":4.1,"x":-15.9},{"z":12.2,"x":11.8},{"z":-19.9,"x":-7.9}]},"tbat_building_cute_animal_wooden_figurines_3":{"has_tbat_skin":true,"points":[{"z":-19.5,"x":8}],"prefab":"tbat_building_cute_animal_wooden_figurines"},"tbat_plant_crimson_bramblefruit":{"prefab":"tbat_plant_crimson_bramblefruit","points":[{"z":0,"x":11.9},{"z":12,"x":-12.2},{"z":-15.8,"x":-12}]},"tbat_plant_cherry_blossom_tree":{"prefab":"tbat_plant_cherry_blossom_tree","points":[{"z":-8.1,"x":0},{"z":0.4,"x":-15.9},{"z":15.9,"x":8.2},{"z":-7.7,"x":20.1}]},"wall_tbat_wood":{"health_percent":1,"points":[{"z":9.5,"x":19.5},{"z":-1.5,"x":-23.5},{"z":14.5,"x":19.5},{"z":-6.5,"x":-23.5}],"prefab":"wall_tbat_wood"},"grass":{"prefab":"grass","points":[{"z":9.1,"x":14.5},{"z":-12,"x":-15.5}]},"tbat_building_cute_animal_wooden_figurines_2":{"has_tbat_skin":true,"points":[{"z":12,"x":0},{"z":-12,"x":12}],"prefab":"tbat_building_cute_animal_wooden_figurines"},"rock2":{"prefab":"rock2","points":[{"z":-7.9,"x":7.8},{"z":16,"x":-8.2}]}}'
        TBAT.MAP:DecorateIslandByAnchor(data,x,y,z)
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 记忆水晶矿源
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_c","resources_memory_crystal_ore",function(x,y,z)
        local radius = 20
        local test_inst = SpawnPrefab("tbat_resources_memory_crystal_ore_core")
        local avalable_points = {}
        while radius > 5 do
            local temp_points = TBAT.FNS:GetSurroundPoints({
                target = Vector3(x,y,z),
                range = radius,
                num = radius*4*5
            })
            for k, pt in pairs(temp_points) do
                if TheWorld.Map:CanDeployAtPoint(pt,test_inst) then
                    table.insert(avalable_points,pt)
                end
            end
            radius = radius - 1
        end
        test_inst:Remove()
        if #avalable_points == 0 then
            return
        end
        local points = TBAT.FNS:GetRandomDiffrenceValuesFromTable(avalable_points, math.random(6,8))
        for k, pt in pairs(points) do 
            SpawnPrefab("tbat_resources_memory_crystal_ore_3").Transform:SetPosition(pt.x,pt.y,pt.z)
        end
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------