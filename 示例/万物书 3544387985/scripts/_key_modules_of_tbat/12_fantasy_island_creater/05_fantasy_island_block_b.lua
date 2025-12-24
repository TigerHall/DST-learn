-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    TBAT.MAP:CreateBlock(name,tile_start_x,tile_start_y)

    TheWorld.Map:GetTileAtPoint(x,y,z)



]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- a 区域
    TBAT.MAP:AddBlock("fantasy_island_block_b",function(start_x,start_y)
        -----------------------------------------------------------------------------------
        ---
            print("幻想岛屿区域 _b 开始创建")
            local start_time = os.clock()
        -----------------------------------------------------------------------------------
        ---
            local width,height = 10,14
            local AA = WORLD_TILES["OCEAN_COASTAL"]
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("turf_savanna")
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("DIRT")
            local BB = WORLD_TILES[string.upper("tbat_turf_pearblossom_brewed_with_snow")]
            local data = {
                AA,AA,AA,BB,BB,AA,BB,BB,AA,AA,
                AA,AA,BB,BB,BB,BB,BB,BB,BB,AA,
                AA,AA,BB,BB,BB,BB,BB,BB,BB,AA,
                AA,AA,AA,BB,BB,BB,BB,BB,AA,AA,
                AA,AA,BB,BB,BB,BB,BB,BB,BB,AA,
                AA,AA,BB,BB,BB,BB,BB,BB,BB,AA,
                AA,AA,AA,BB,BB,AA,BB,BB,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
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
                {6,1},{6,7},{6,8},{6,9},{6,10},{5,10},{4,10},{4,11},{4,12},{3,12},{2,12},{1,12}
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
            local offset_y = TILE_SCALE * 3
            -- SpawnPrefab("tbat_room_anchor_fantasy_island_b").Transform:SetPosition(start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            TBAT.MAP:CreateUniqueAnchor("tbat_room_anchor_fantasy_island_b",start_pt.x+offset_x , 0 , start_pt.z+offset_y)
        -----------------------------------------------------------------------------------
        ---
            local end_time = os.clock()
            local cost_time = end_time - start_time
            print(string.format("幻想岛屿区域 _b 创建耗时 : %.4f 秒", cost_time))
        -----------------------------------------------------------------------------------    
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 装修（debug）
    -- if TBAT.DEBUGGING then
    --     TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_b","debug_pighouse",function(x,y,z)
    --         SpawnPrefab("pighouse").Transform:SetPosition(x,y,z)
    --     end)
    -- end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_b","level_1",function(x,y,z)
        local data = '{"grass":{"prefab":"grass","points":[{"z":-7.8,"x":11.7},{"z":11.2,"x":9.5}]},"sapling_moon":{"prefab":"sapling_moon","points":[{"z":4.3,"x":3.7},{"z":-7.9,"x":-4},{"z":-11.6,"x":3.8},{"z":-4.1,"x":-12.2},{"z":7.9,"x":12},{"z":8.2,"x":-12.2},{"z":-12.4,"x":7.9},{"z":12.2,"x":-8.1}]},"driftwood_small1":{"prefab":"driftwood_small1","points":[{"z":12.5,"x":-3.9}]},"tbat_building_cute_animal_decorative_figurines_2":{"has_tbat_skin":true,"points":[{"z":0,"x":0}],"prefab":"tbat_building_cute_animal_decorative_figurines"},"driftwood_tall":{"prefab":"driftwood_tall","points":[{"z":8,"x":7.7}]},"tbat_plant_pear_blossom_tree":{"prefab":"tbat_plant_pear_blossom_tree","points":[{"z":-7.8,"x":7.9},{"z":8,"x":-8},{"z":-3.9,"x":12.3},{"z":-11.7,"x":-8.1}]},"rock_moon":{"prefab":"rock_moon","points":[{"z":-3.4,"x":-4.2},{"z":12.4,"x":8}]},"driftwood_small2":{"prefab":"driftwood_small2","points":[{"z":-7.1,"x":-8.2}]},"wall_tbat_wood":{"health_percent":1,"points":[{"z":-15.5,"x":-2.5},{"z":-15.5,"x":2.5},{"z":15.5,"x":-2.5},{"z":15.5,"x":2.5}],"prefab":"wall_tbat_wood"}}'
        TBAT.MAP:DecorateIslandByAnchor(data,x,y,z)
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------