-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    TBAT.MAP:CreateBlock(name,tile_start_x,tile_start_y)

    TheWorld.Map:GetTileAtPoint(x,y,z)



]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- a 区域
    TBAT.MAP:AddBlock("fantasy_island_block_a",function(start_x,start_y)
        -----------------------------------------------------------------------------------
        ---
            print("幻想岛屿区域 _a 开始创建")
            local start_time = os.clock()
        -----------------------------------------------------------------------------------
        ---
            local width,height = 10,16
            local AA = WORLD_TILES["OCEAN_COASTAL"]
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("turf_savanna")
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("DIRT")
            local BB = WORLD_TILES[string.upper("tbat_turf_pearblossom_brewed_with_snow")]
            -- local CC = TBAT.MAP:GetTileIndexByItemPrefab("DIRT")
            local CC = WORLD_TILES[string.upper("tbat_turf_fallen_cherry_blossoms")]
            local data = {
                    AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                    AA,BB,AA,BB,AA,AA,AA,AA,AA,AA,
                    BB,BB,BB,BB,BB,AA,AA,AA,AA,AA,
                    AA,BB,BB,BB,AA,AA,AA,AA,AA,AA,
                    AA,AA,BB,AA,AA,AA,AA,AA,AA,AA,
                    AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                    AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                    AA,AA,AA,CC,CC,AA,CC,CC,AA,AA,
                    AA,AA,CC,CC,CC,CC,CC,CC,CC,AA,
                    AA,AA,CC,CC,CC,CC,CC,CC,CC,AA,
                    AA,AA,CC,CC,CC,CC,CC,CC,CC,AA,
                    AA,AA,AA,CC,CC,CC,CC,CC,AA,AA,
                    AA,AA,AA,AA,CC,CC,CC,AA,AA,AA,
                    AA,AA,AA,AA,AA,CC,AA,AA,AA,AA,
                    AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                    AA,AA,AA,AA,AA,AA,AA,AA,AA,AA
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
                {1,9},{2,9},{1,13},{2,13},{3,13},{6,15},{6,16}
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
            local offset_y = TILE_SCALE * 9
            -- SpawnPrefab("tbat_room_anchor_fantasy_island_a").Transform:SetPosition(start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            TBAT.MAP:CreateUniqueAnchor("tbat_room_anchor_fantasy_island_a",start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            offset_x = TILE_SCALE * 2
            offset_y = TILE_SCALE * 2
            -- SpawnPrefab("tbat_room_anchor_fantasy_island_g").Transform:SetPosition(start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            TBAT.MAP:CreateUniqueAnchor("tbat_room_anchor_fantasy_island_g",start_pt.x+offset_x , 0 , start_pt.z+offset_y)
        -----------------------------------------------------------------------------------
        ---
            local end_time = os.clock()
            local cost_time = end_time - start_time
            print(string.format("幻想岛屿区域 _a 创建耗时 : %.4f 秒", cost_time))
        -----------------------------------------------------------------------------------    
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 装修（debug）
    -- if TBAT.DEBUGGING then
    --     TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_a","debug_pighouse",function(x,y,z)
    --         SpawnPrefab("pighouse").Transform:SetPosition(x,y,z)
    --     end)
    -- end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_g","level_1",function(x,y,z)
        local data = '{"tbat_building_cute_animal_wooden_figurines_3":{"has_tbat_skin":true,"points":[{"z":8,"x":0}],"prefab":"tbat_building_cute_animal_wooden_figurines"},"tbat_plant_pear_blossom_tree":{"prefab":"tbat_plant_pear_blossom_tree","points":[{"z":0.1,"x":4},{"z":3.7,"x":-3.8}]},"sapling_moon":{"prefab":"sapling_moon","points":[{"z":4.2,"x":4},{"z":0.2,"x":-8.1}]},"driftwood_tall":{"prefab":"driftwood_tall","points":[{"z":0.2,"x":7.9}]}}'
        TBAT.MAP:DecorateIslandByAnchor(data,x,y,z)
    end)
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_a","level_1",function(x,y,z)
        local data = '{"mushtree_medium":{"prefab":"mushtree_medium","points":[{"z":3.9,"x":7.9},{"z":-7.6,"x":-8.3}]},"tbat_plant_crimson_bramblefruit":{"prefab":"tbat_plant_crimson_bramblefruit","points":[{"z":-7.7,"x":4},{"z":8.5,"x":3.9},{"z":4.1,"x":-12.2}]},"tbat_plant_cherry_blossom_tree":{"scale":[-1,1,1],"points":[{"z":-2,"x":-7.8},{"z":-2,"x":8.1}],"prefab":"tbat_plant_cherry_blossom_tree"},"tbat_building_cute_pet_stone_figurines":{"prefab":"tbat_building_cute_pet_stone_figurines","points":[{"z":9,"x":-9},{"z":13,"x":-5},{"z":11,"x":-11},{"z":10,"x":-12.5}]},"tbat_building_cherry_blossom_rabbit_swing":{"prefab":"tbat_building_cherry_blossom_rabbit_swing","points":[{"z":4,"x":0}]},"marbleshrub":{"prefab":"marbleshrub","points":[{"z":-7.9,"x":-4.2},{"z":12.3,"x":4}]},"wall_tbat_wood":{"health_percent":1,"points":[{"z":-1.5,"x":-15.5},{"z":-6.5,"x":-15.5},{"z":14.5,"x":-9.5},{"z":19.5,"x":-2.5},{"z":19.5,"x":2.5}],"prefab":"wall_tbat_wood"},"tbat_building_cute_animal_wooden_figurines_2":{"has_tbat_skin":true,"points":[{"z":12,"x":-4}],"prefab":"tbat_building_cute_animal_wooden_figurines"},"marbletree":{"prefab":"marbletree","points":[{"z":4.3,"x":12.2}]},"tbat_building_cute_animal_decorative_figurines":{"prefab":"tbat_building_cute_animal_decorative_figurines","points":[{"z":10,"x":-10.5}]}}'
        TBAT.MAP:DecorateIslandByAnchor(data,x,y,z)
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------