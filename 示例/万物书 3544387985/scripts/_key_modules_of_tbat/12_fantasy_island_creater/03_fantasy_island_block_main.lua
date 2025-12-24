-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    TBAT.MAP:CreateBlock(name,tile_start_x,tile_start_y)

    TheWorld.Map:GetTileAtPoint(x,y,z)

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    TBAT.MAP:AddBlock("fantasy_island_blocks",function(start_x,start_y)
        ---------------------------------------------------------------------------------------
        --- 
            print("fantasy_island_blocks mian start",start_x,start_y)
        ---------------------------------------------------------------------------------------
        --- 
            local island_w, island_h = 36, 30
        ---------------------------------------------------------------------------------------
        --- 删除内部实体
            for y = start_y, start_y + island_h - 1 do
                for x = start_x, start_x + island_w - 1 do
                    local data = TBAT.MAP:GetTileData(x, y)
                    if type(data) == "table" and type(data.ents) == "table" then
                        for k, v in pairs(data.ents) do
                            v:Remove()
                        end
                    end
                end
            end
        ---------------------------------------------------------------------------------------
        --- 小区块
            local blocks_data = {

                { name = "fantasy_island_block_main",       x   =   start_x + 12  -1 ,   y   =   start_y     },
                { name = "fantasy_island_block_a",          x   =   start_x + 27  -1 ,   y   =   start_y     },
                { name = "fantasy_island_block_b",          x   =   start_x + 27  -1 ,   y   =   start_y + 17 -1     },
                { name = "fantasy_island_block_c",          x   =   start_x + 16  -1 ,   y   =   start_y + 17 -1     },
                { name = "fantasy_island_block_d",          x   =   start_x          ,   y   =   start_y + 17 -1     },
                { name = "fantasy_island_block_e",          x   =   start_x          ,   y   =   start_y   },

            }

            for i, data in ipairs(blocks_data) do
                local temp_inst = CreateEntity()
                print("岛屿添加子区域生成器。",data.name)
                TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(temp_inst,i,function()
                    temp_inst:Remove()
                    TBAT.MAP:CreateBlock(data.name,data.x,data.y)
                end)
            end
        ---------------------------------------------------------------------------------------

    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- main 区域
    TBAT.MAP:AddBlock("fantasy_island_block_main",function(start_x,start_y)
        -----------------------------------------------------------------------------------
        ---
            print("幻想岛屿区域 _main 开始创建")
            local start_time = os.clock()
        -----------------------------------------------------------------------------------
        ---
            local width,height = 15,16
            -- local AA = 201
            local AA = WORLD_TILES["OCEAN_COASTAL"]
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("turf_savanna")
            -- local BB = TBAT.MAP:GetTileIndexByItemPrefab("DIRT")
            local BB = WORLD_TILES[string.upper("tbat_turf_emerald_feather_leaves")]
            local CC = WORLD_TILES[string.upper("cotl_brick")]
            local data = {
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,AA,
                AA,AA,AA,AA,BB,AA,AA,AA,AA,AA,BB,AA,AA,AA,AA,
                AA,AA,AA,BB,BB,BB,AA,AA,AA,BB,BB,BB,AA,AA,AA,
                AA,AA,AA,BB,BB,BB,AA,AA,AA,BB,BB,BB,AA,AA,AA,
                AA,AA,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,AA,AA,
                AA,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,AA,
                BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,
                AA,CC,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,CC,AA,
                BB,AA,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,AA,BB,
                BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,
                BB,AA,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,AA,BB,
                AA,CC,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,CC,AA,
                BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,
                AA,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,AA,
                AA,AA,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,BB,AA,AA
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
                {1,9},{2,10},{2,12},{1,13},{15,9},{14,10},{14,12},{15,13}
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
            local offset_x = TILE_SCALE * 7
            local offset_y = TILE_SCALE * 10
            -- SpawnPrefab("tbat_room_anchor_fantasy_island_main").Transform:SetPosition(start_pt.x+offset_x , 0 , start_pt.z+offset_y)
            TBAT.MAP:CreateUniqueAnchor("tbat_room_anchor_fantasy_island_main",start_pt.x+offset_x , 0 , start_pt.z+offset_y)
        -----------------------------------------------------------------------------------
        ---
            local end_time = os.clock()
            local cost_time = end_time - start_time
            print(string.format("幻想岛屿区域 _main 创建耗时 : %.4f 秒", cost_time))
        -----------------------------------------------------------------------------------    
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 装修（debug）
    -- if TBAT.DEBUGGING then
    --     TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_main","debug_pighouse",function(x,y,z)
    --         SpawnPrefab("pighouse").Transform:SetPosition(x,y,z)
    --     end)
    -- end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 基于锚点 半径35 内所有东西囊括。
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_main","level_1",function(x,y,z)
        local str = '{"grass":{"prefab":"grass","points":[{"z":8.6,"x":-11.3},{"z":6.1,"x":-13.5},{"z":8,"x":-17.4},{"z":-19,"x":3.7},{"z":-11.4,"x":15.7},{"z":18.7,"x":9.2},{"z":19.9,"x":11.6},{"z":-16.6,"x":-18.9},{"z":-16.2,"x":19.6},{"z":-15.5,"x":-20.7},{"z":19.9,"x":-20.2}]},"tbat_building_cute_animal_wooden_figurines":{"prefab":"tbat_building_cute_animal_wooden_figurines","points":[{"z":0,"x":8.5},{"z":0,"x":-8.5},{"z":8.5,"x":0},{"z":-8.5,"x":0}]},"tbat_building_conch_shell_decoration_4":{"has_tbat_skin":true,"points":[{"z":8.5,"x":-16.5},{"z":21.5,"x":7},{"z":-14,"x":-18.5},{"z":17,"x":20},{"z":-11,"x":-29}],"prefab":"tbat_building_conch_shell_decoration"},"tbat_building_conch_shell_decoration_2":{"has_tbat_skin":true,"points":[{"z":-18.5,"x":3},{"z":21,"x":-10.5},{"z":18,"x":-18},{"z":-11.5,"x":23.5},{"z":16.5,"x":20.5}],"prefab":"tbat_building_conch_shell_decoration"},"tbat_building_trade_notice_board":{"prefab":"tbat_building_trade_notice_board","points":[{"z":0,"x":-24}]},"tbat_building_recruitment_notice_board":{"prefab":"tbat_building_recruitment_notice_board","points":[{"z":0,"x":24}]},"tbat_the_tree_of_all_things":{"prefab":"tbat_the_tree_of_all_things","points":[{"z":0,"x":0}]},"wall_tbat_wood":{"health_percent":1,"points":[{"z":-7.5,"x":-0.5},{"z":0.5,"x":7.5},{"z":-0.5,"x":-7.5},{"z":-0.5,"x":7.5},{"z":7.5,"x":0.5},{"z":0.5,"x":-7.5},{"z":7.5,"x":-0.5},{"z":-7.5,"x":0.5},{"z":5.5,"x":6.5},{"z":6.5,"x":-5.5},{"z":6.5,"x":5.5},{"z":-5.5,"x":-6.5},{"z":-5.5,"x":6.5},{"z":-6.5,"x":5.5},{"z":-6.5,"x":-5.5},{"z":5.5,"x":-6.5},{"z":-5.5,"x":31.5},{"z":5.5,"x":-31.5},{"z":5.5,"x":31.5},{"z":-5.5,"x":-31.5},{"z":-10.5,"x":31.5},{"z":-10.5,"x":-31.5},{"z":10.5,"x":-31.5},{"z":10.5,"x":31.5}],"prefab":"wall_tbat_wood"},"tbat_plant_valorbush":{"prefab":"tbat_plant_valorbush","points":[{"z":16.1,"x":15.9},{"z":16.4,"x":-16.2},{"z":12.1,"x":-20.2},{"z":12.2,"x":20.2}]},"reeds":{"prefab":"reeds","points":[{"z":-12.1,"x":24.5},{"z":13.7,"x":25.1},{"z":-12.7,"x":26.4},{"z":14.2,"x":-26.1},{"z":-11.6,"x":-28.1},{"z":12.4,"x":-27.7},{"z":12,"x":28.1}]},"tbat_building_cute_pet_stone_figurines_5":{"has_tbat_skin":true,"points":[{"z":-30,"x":-10}],"prefab":"tbat_building_cute_pet_stone_figurines"},"tbat_building_plum_blossom_table":{"prefab":"tbat_building_plum_blossom_table","points":[{"z":-28,"x":-12}]},"tbat_building_woodland_lamp":{"prefab":"tbat_building_woodland_lamp","points":[{"z":-8,"x":-24},{"z":8,"x":-24},{"z":-8,"x":24},{"z":8,"x":24}]},"tbat_building_stump_table":{"prefab":"tbat_building_stump_table","points":[{"z":-28,"x":12}]},"tbat_building_star_and_cloud_decoration":{"prefab":"tbat_building_star_and_cloud_decoration","points":[{"z":-26,"x":-10},{"z":-26,"x":14},{"z":-30,"x":10},{"z":-30,"x":-14}]},"tbat_building_cute_pet_stone_figurines_3":{"has_tbat_skin":true,"points":[{"z":19.5,"x":7.5},{"z":-15,"x":-21.5},{"z":-26,"x":10},{"z":-26,"x":-14},{"z":13,"x":27},{"z":21.5,"x":-21.5}],"prefab":"tbat_building_cute_pet_stone_figurines"},"evergreen_sparse":{"prefab":"evergreen_sparse","points":[{"z":-11.7,"x":2.2},{"z":-15.1,"x":-4.1},{"z":20,"x":9.9},{"z":-19.6,"x":17},{"z":-18.3,"x":-20.7},{"z":-14.8,"x":23.9},{"z":11.5,"x":26.1},{"z":-15.4,"x":-24.9},{"z":20.8,"x":-20.9},{"z":17.8,"x":-23.7},{"z":-31.1,"x":11.8}]},"tbat_building_cute_pet_stone_figurines_4":{"has_tbat_skin":true,"points":[{"z":9,"x":-10.5},{"z":0.5,"x":16},{"z":-16,"x":19},{"z":-19.5,"x":-18},{"z":-11,"x":-27},{"z":-30,"x":14}],"prefab":"tbat_building_cute_pet_stone_figurines"}}'
        TBAT.MAP:DecorateIslandByAnchor(str,x,y,z)

    end)
    TBAT.MAP:AddAnchorDecorateTask("tbat_room_anchor_fantasy_island_main","tbat_room_mini_portal_door",function(x,y,z)
        
        SpawnPrefab("tbat_room_mini_portal_door").Transform:SetPosition(x-18,y,z+21)

    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------