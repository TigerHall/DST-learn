-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local black_list_tags = {"epic","charactor","cocoon_home","shadecanopy","structure","antlion_sinkhole_blocker","oceanvine","plant"}
    local black_list_prefabs = {

    }
    local checked_in_black_list = {}
    local function inst_in_black_list(inst)
        if checked_in_black_list[inst] ~= nil then
            return checked_in_black_list[inst]
        end  
        if inst:HasOneOfTags(black_list_tags) then
            checked_in_black_list[inst] = true
            return true
        end
        if black_list_prefabs[inst.prefab] then
            checked_in_black_list[inst] = true
            return true
        end
        checked_in_black_list[inst] = false
        return false        
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建岛屿任务
    TBAT.MAP:SetIslandTaskFn("fantasy_island",function()
        --------------------------------------------------------------------------
        ---
            print("万物书 幻想岛屿 开始搜索生成区域")
        --------------------------------------------------------------------------
        --- 数据初始化
            local map_w,map_h = TBAT.MAP:GetSize() -- 地图尺寸
            local island_w,island_h = 36,30 -- 岛屿尺寸
        --------------------------------------------------------------------------
        --- 计时器
            local start_time = os.clock(); 
        --------------------------------------------------------------------------
        --- single tile avalable checker
            local function this_tile_is_avalable(x,y)
                ------------------------------------------------------------------
                --
                    local data = TBAT.MAP:GetTileData(x,y)
                ------------------------------------------------------------------
                --[[
                    -- --- 虚空海 的 tile 为 65535
                    --     --- 洞穴里的虚空tile 为 1
                    --     ---  201 ~ 247 都是海洋
                    --     --- 浅海 tile  201
                    --     --- 中海 tile  203
                    --     --- 深海 tile  204
                    --     --- 其他  205 
                    --     --- API   IsOceanTile(tile)
                    --     --- 牛毛地毯  12
                    --     --- 棋盘地毯  11    
                ]]
                    
                    local tile_type = data.tile
                    -- if tile_type < 201 or tile_type > 247 then
                    --     return false
                    -- end
                    if not TheWorld.Map:IsTileOcean(tile_type) then
                        return false
                    end
                ------------------------------------------------------------------
                --- 内部inst遍历
                    for k, temp_inst in pairs(data.ents or {}) do
                        if inst_in_black_list(temp_inst) then
                            return false
                        end
                    end
                ------------------------------------------------------------------
                --- 必须使用 TheSim:FindEntities ，这条代码在C++层有加速优化。
                    local mid_pt = data.mid_pt
                    local ents = TheSim:FindEntities(mid_pt.x,0,mid_pt.z, 30, nil, nil, nil)
                    for k, v in pairs(ents) do
                        if inst_in_black_list(v) then
                            return false
                        end
                    end
                ------------------------------------------------------------------
                return true
            end
            local single_avalable_locations = {}
            for y = 1, map_h do
                single_avalable_locations[y] = single_avalable_locations[y] or {}                
                for x = 1, map_w do
                    single_avalable_locations[y][x] = TheWorld.Map:IsTileOcean(TBAT.MAP:GetTileData(x,y).tile)
                end
            end
        --------------------------------------------------------------------------
        --- 遍历所有实体
            for k, temp_inst in pairs(Ents) do
                if temp_inst and temp_inst.Transform and inst_in_black_list(temp_inst) then
                    local tile_type ,tile_x,tile_y = TBAT.MAP:GetTileByInst(temp_inst)
                    if tile_type and not TheWorld.Map:IsTileOcean(tile_type) then
                        single_avalable_locations[tile_y][tile_x] = false
                    end
                end
            end
            --- 大约消耗0.02s
        --------------------------------------------------------------------------
        --- area tile avalable checker
            -- 使用田字快速查找法
            local function is_this_area_tile_avalable(start_x,start_y,area_w,area_h)
                --------------------------------------------------------------------
                --- 角落4点+中间一点、其他点数。
                    local main_points = {
                        {x = start_x,y = start_y}, -- 左上
                        {x = start_x + area_w - 1,y = start_y}, -- 右上
                        {x = start_x,y = start_y + area_h - 1}, -- 左下
                        {x = start_x + area_w - 1,y = start_y + area_h - 1},    -- 右下
                        {x = math.ceil(start_x + area_w / 2),y = math.ceil(start_y + area_h / 2)},  -- 中心                         
                    }                        
                --------------------------------------------------------------------
                    for k, pt in pairs(main_points) do
                        if single_avalable_locations[pt.y][pt.x] and not this_tile_is_avalable(pt.x,pt.y) then
                            single_avalable_locations[pt.y][pt.x] = false
                            return false
                        end
                    end
                --------------------------------------------------------------------
                --- 三行
                    local lines = {
                        start_y,
                        start_y + area_h - 1,
                        math.ceil( start_y + area_h / 2 )
                    }
                    for k, temp_y in pairs(lines) do
                        for x = start_x, start_x + area_w - 1 do
                            if single_avalable_locations[temp_y][x] == false then
                                return false
                            end
                            if this_tile_is_avalable(x,temp_y) then

                            else
                                single_avalable_locations[temp_y][x] = false
                                return false
                            end
                        end
                    end
                --------------------------------------------------------------------
                --- 三列
                    local lines = {
                        start_x,
                        start_x + area_w - 1,
                        math.ceil(start_x + area_w / 2)
                    }
                    for k, temp_x in pairs(lines) do
                        for y = start_y, start_y + area_h - 1 do
                            if single_avalable_locations[y][temp_x] == false then
                                return false
                            end
                            if this_tile_is_avalable(temp_x, y) then
                                
                            else
                                single_avalable_locations[y][temp_x] = false
                                return false
                            end
                        end
                    end
                --------------------------------------------------------------------
                return true
            end
        --------------------------------------------------------------------------
        ---
            local all_avalable_start_locations = {}
        --------------------------------------------------------------------------
        --- 遍历所有地图块
            print("fake error",map_h-island_h,map_w-island_w)
            for tile_start_y = 1,map_h-island_h do
                for tile_start_x = 1,map_w-island_w do
                    -- print("tile_start_x,tile_start_y",tile_start_x,tile_start_y)
                    if is_this_area_tile_avalable(tile_start_x,tile_start_y,island_w,island_h) then
                        table.insert(all_avalable_start_locations,{tile_x=tile_start_x,tile_y=tile_start_y})                        
                    end
                end
            end
        --------------------------------------------------------------------------
        --------------------------------------------------------------------------
        ---
            local end_time = os.clock();
            print(string.format("万物书 幻想岛屿 生成区域搜索 时间花费 : %.4f", end_time - start_time));
            print("寻找到可创建坐标数量:",#all_avalable_start_locations)
        --------------------------------------------------------------------------
        ---
            return false
        --------------------------------------------------------------------------

    end,false)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------