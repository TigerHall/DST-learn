-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    TBAT.MAP:CreateBlock(name,tile_start_x,tile_start_y)

    TheWorld.Map:GetTileAtPoint(x,y,z)



]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- a 区域
    TBAT.MAP:AddBlock("fantasy_island_block_e",function(start_x,start_y)
        -----------------------------------------------------------------------------------
        ---
            print("幻想岛屿区域 _e 开始创建")
            local start_time = os.clock()
        -----------------------------------------------------------------------------------
        ---
            local width,height = 11,16
            local AA = WORLD_TILES["OCEAN_COASTAL"]
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("turf_savanna")
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("DIRT")
            local BB = WORLD_TILES[string.upper("tbat_turf_pearblossom_brewed_with_snow")]
            -- local CC = TBAT.MAP:GetTileIndexByItemPrefab("DIRT")
            local CC = WORLD_TILES[string.upper("tbat_turf_fallen_cherry_blossoms")]
            local data = {
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,BB,AA,BB,AA,
                AA,AA,AA,AA,AA,AA,BB,BB,BB,BB,BB,
                AA,AA,AA,AA,AA,AA,AA,BB,BB,BB,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,BB,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,BB,BB,AA,BB,BB,AA,AA,AA,AA,
                AA,BB,CC,CC,CC,CC,CC,BB,AA,AA,AA,
                AA,BB,CC,CC,CC,CC,CC,BB,AA,AA,AA,
                AA,AA,CC,CC,CC,CC,CC,AA,AA,AA,AA,
                AA,BB,CC,CC,CC,CC,CC,BB,AA,AA,AA,
                AA,BB,CC,CC,CC,CC,CC,BB,AA,AA,AA,
                AA,AA,BB,BB,AA,BB,BB,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
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
                {9,9},{10,9},{11,9},{9,13},{10,13},{11,13},{5,14},{5,15},{5,16}
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
            local offset_x = TILE_SCALE * 4
            local offset_y = TILE_SCALE * 10
            -- SpawnPrefab("tbat_room_anchor_fantasy_island_e").Transform:SetPosition(start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            TBAT.MAP:CreateUniqueAnchor("tbat_room_anchor_fantasy_island_e",start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            offset_x = TILE_SCALE * 8
            offset_y = TILE_SCALE * 2
            -- SpawnPrefab("tbat_room_anchor_fantasy_island_f").Transform:SetPosition(start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            TBAT.MAP:CreateUniqueAnchor("tbat_room_anchor_fantasy_island_f",start_pt.x+offset_x , 0 , start_pt.z+offset_y)
        -----------------------------------------------------------------------------------
        ---
            local end_time = os.clock()
            local cost_time = end_time - start_time
            print(string.format("幻想岛屿区域 _e 创建耗时 : %.4f 秒", cost_time))
        -----------------------------------------------------------------------------------    
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 装修（debug）
    -- if TBAT.DEBUGGING then
    --     TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_e","debug_pighouse",function(x,y,z)
    --         SpawnPrefab("pighouse").Transform:SetPosition(x,y,z)
    --     end)
    -- end
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_e","level_1",function(x,y,z)
        local data = '{"tbat_building_cute_animal_wooden_figurines":{"prefab":"tbat_building_cute_animal_wooden_figurines","points":[{"z":-3.5,"x":-9},{"z":-9,"x":3.5},{"z":-3.5,"x":9},{"z":-9,"x":-3.5},{"z":3.5,"x":-9},{"z":3.5,"x":9},{"z":9.5,"x":-3.5},{"z":9.5,"x":3.5},{"z":7,"x":7.5},{"z":7,"x":-7.5},{"z":-9,"x":-5.5},{"z":-9,"x":5.5},{"z":5.5,"x":-9.5},{"z":5.5,"x":9.5},{"z":9.5,"x":-6.5},{"z":6.5,"x":9.5},{"z":9.5,"x":6.5},{"z":6.5,"x":-9.5},{"z":-8.5,"x":-8},{"z":-8.5,"x":8}]},"tbat_building_cute_pet_stone_figurines_5":{"has_tbat_skin":true,"points":[{"z":-8.5,"x":5},{"z":-8.5,"x":-5}],"prefab":"tbat_building_cute_pet_stone_figurines","scale":[-1,1,1]},"tbat_building_cute_pet_stone_figurines":{"scale":[-1,1,1],"points":[{"z":-9,"x":-0.5},{"z":-9,"x":0.5},{"z":-8,"x":7.5},{"z":-8,"x":-7.5}],"prefab":"tbat_building_cute_pet_stone_figurines"},"wall_wood":{"health_percent":1,"points":[{"z":8.5,"x":2.5},{"z":8.5,"x":-2.5},{"z":-4.5,"x":-9.5},{"z":-9.5,"x":-4.5},{"z":4.5,"x":9.5},{"z":4.5,"x":-9.5},{"z":-4.5,"x":9.5},{"z":-9.5,"x":4.5},{"z":8.5,"x":7.5},{"z":7.5,"x":8.5},{"z":7.5,"x":-8.5},{"z":8.5,"x":-7.5},{"z":-9.5,"x":-6.5},{"z":-9.5,"x":6.5},{"z":-10.5,"x":-5.5},{"z":-10.5,"x":5.5}],"prefab":"wall_wood"},"wall_stone":{"health_percent":1,"points":[{"z":8.5,"x":3.5},{"z":8.5,"x":-3.5},{"z":-9.5,"x":2.5},{"z":2.5,"x":9.5},{"z":-9.5,"x":-2.5},{"z":-2.5,"x":-9.5},{"z":-2.5,"x":9.5},{"z":2.5,"x":-9.5},{"z":8.5,"x":-6.5},{"z":8.5,"x":6.5},{"z":-10.5,"x":3.5},{"z":3.5,"x":10.5},{"z":-3.5,"x":10.5},{"z":-10.5,"x":-3.5},{"z":3.5,"x":-10.5},{"z":-3.5,"x":-10.5}],"prefab":"wall_stone"},"tbat_plant_valorbush":{"prefab":"tbat_plant_valorbush","points":[{"z":-12,"x":-8},{"z":-12,"x":8},{"z":-8,"x":-12},{"z":8,"x":-12},{"z":12,"x":8},{"z":12,"x":-8},{"z":8,"x":12},{"z":-8,"x":12}]},"tbat_building_woodland_lamp":{"prefab":"tbat_building_woodland_lamp","points":[{"z":-13.5,"x":2.5},{"z":-13.5,"x":-2.5},{"z":2.5,"x":-13.5},{"z":13.5,"x":2.5},{"z":13.5,"x":-2.5},{"z":-2.5,"x":-13.5},{"z":2.5,"x":13.5},{"z":-2.5,"x":13.5}]},"tbat_building_cute_pet_stone_figurines_3":{"has_tbat_skin":true,"points":[{"z":-9,"x":-1.5},{"z":-9,"x":1.5},{"z":9.5,"x":1.5},{"z":9.5,"x":-2}],"prefab":"tbat_building_cute_pet_stone_figurines","scale":[-1,1,1]},"mushroom_light2":{"prefab":"mushroom_light2","points":[{"z":-8.5,"x":-7},{"z":-8.5,"x":7}]},"wall_tbat_wood":{"health_percent":1,"points":[{"z":8.5,"x":-4.5},{"z":8.5,"x":4.5},{"z":8.5,"x":-5.5},{"z":8.5,"x":5.5},{"z":0.5,"x":-10.5},{"z":0.5,"x":10.5},{"z":-0.5,"x":10.5},{"z":-10.5,"x":0.5},{"z":-0.5,"x":-10.5},{"z":-10.5,"x":-0.5},{"z":-10.5,"x":-1.5},{"z":-10.5,"x":1.5},{"z":-1.5,"x":10.5},{"z":-1.5,"x":-10.5},{"z":1.5,"x":10.5},{"z":1.5,"x":-10.5},{"z":-5.5,"x":9.5},{"z":-5.5,"x":-9.5},{"z":-9.5,"x":7.5},{"z":-9.5,"x":-7.5},{"z":15.5,"x":2.5},{"z":15.5,"x":-2.5},{"z":-5.5,"x":15.5},{"z":5.5,"x":15.5},{"z":-10.5,"x":15.5},{"z":10.5,"x":15.5}],"prefab":"wall_tbat_wood"}}'
        TBAT.MAP:DecorateIslandByAnchor(data,x,y,z)
    end)
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_f","level_1",function(x,y,z)
        local data = '{"sapling_moon":{"prefab":"sapling_moon","points":[{"z":0.3,"x":-0.3},{"z":4.2,"x":-3.8}]},"rock_moon":{"prefab":"rock_moon","points":[{"z":0.7,"x":-8.1}]},"tbat_plant_pear_blossom_tree":{"prefab":"tbat_plant_pear_blossom_tree","points":[{"z":0.5,"x":-3.9},{"z":4,"x":3.8}]},"driftwood_small2":{"prefab":"driftwood_small2","points":[{"z":0.3,"x":7.9}]},"tbat_building_cute_animal_decorative_figurines_4":{"has_tbat_skin":true,"points":[{"z":8,"x":0}],"prefab":"tbat_building_cute_animal_decorative_figurines"}}'
        TBAT.MAP:DecorateIslandByAnchor(data,x,y,z)
    end)
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_e","tbat_building_fantasy_shop",function(x,y,z)
        SpawnPrefab("tbat_building_fantasy_shop").Transform:SetPosition(x,y,z)
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------