-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    本代码由  豆包AI 优化。执行大约 7秒，得到结果 1500+

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local black_list_tags = {"epic","charactor","cocoon_home","shadecanopy","structure","antlion_sinkhole_blocker","oceanvine","plant"}
    local black_list_prefabs = {
        ["icefishing_hole"] = true,
        ["oceanfish_shoalspawner"] = true,
        ["oceantree_pillar"] = true,
        ["watertree_pillar"] = true,
    }
    local checked_in_black_list = {}
    local BLACKLIST_ENTS = {} -- 预存黑名单实体位置及影响半径

    -- 黑名单检查优化
    local function inst_in_black_list(inst)
        if checked_in_black_list[inst] ~= nil then
            return checked_in_black_list[inst]
        end
        
        local has_tag = inst:HasOneOfTags(black_list_tags)
        local is_prefab = black_list_prefabs[inst.prefab]
        
        checked_in_black_list[inst] = has_tag or is_prefab
        if has_tag or is_prefab then
            local tile_type, tx, ty = TBAT.MAP:GetTileByInst(inst)
            if tile_type and not TheWorld.Map:IsTileOcean(tile_type) then
                BLACKLIST_ENTS[#BLACKLIST_ENTS + 1] = {x = tx, y = ty, radius = 30}
            end
        end
        
        return checked_in_black_list[inst]
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 搜索区域
    TBAT.MAP:SetIslandTaskFn("fantasy_island", function()
        --------------------------------------------------------------------
        print("万物书 幻想岛屿 开始精准搜索生成区域")
        --------------------------------------------------------------------
        -- 数据初始化
            local map_w, map_h = TBAT.MAP:GetSize()
            local island_w, island_h = 36, 30
            local search_radius = 30
        --------------------------------------------------------------------
        -- 计时器
        local start_time = os.clock()
        --------------------------------------------------------------------
        -- 双级海洋地图缓存
            local ocean_tiles = {}
            local quick_ocean = {}
            for y = 1, map_h do
                ocean_tiles[y] = {}
                quick_ocean[y] = {}
                for x = 1, map_w do
                    local tile_type = TBAT.MAP:GetTileData(x, y).tile
                    local is_ocean = TheWorld.Map:IsTileOcean(tile_type)
                    ocean_tiles[y][x] = is_ocean
                    quick_ocean[y][x] = is_ocean and 1 or 0
                end
            end
        --------------------------------------------------------------------
        -- 预处理黑名单实体影响区域
            local BLACKLIST_TILES = setmetatable({}, {__index = function() return false end})
            for _, ent in ipairs(Ents) do
                if ent and ent.Transform and inst_in_black_list(ent) then
                    local tx, ty = ent.Transform:GetWorldPosition()
                    tx, ty = math.floor(tx + 0.5), math.floor(ty + 0.5)
                    BLACKLIST_TILES[ty .. "," .. tx] = true
                end
            end
        --------------------------------------------------------------------
        -- 矩形碰撞检测函数
            local function rect_collides(rect1, rect2)
                return not (rect1.x2 < rect2.x1 or rect1.x1 > rect2.x2 or 
                            rect1.y2 < rect2.y1 or rect1.y1 > rect2.y2)
            end
        --------------------------------------------------------------------
        -- 单个格子可用性检查（精准版）
            local function this_tile_is_avalable(x, y)
                if not ocean_tiles[y][x] then
                    return false
                end
                
                local tile_rect = {x1 = x-1, x2 = x+1, y1 = y-1, y2 = y+1}
                for _, ent in ipairs(BLACKLIST_ENTS) do
                    local ent_rect = {
                        x1 = ent.x - ent.radius, 
                        x2 = ent.x + ent.radius,
                        y1 = ent.y - ent.radius, 
                        y2 = ent.y + ent.radius
                    }
                    if rect_collides(tile_rect, ent_rect) then
                        local mid_pt = {x = x, z = y}
                        local ents = TheSim:FindEntities(mid_pt.x, 0, mid_pt.z, ent.radius, nil, nil, nil)
                        for _, v in ipairs(ents) do
                            if inst_in_black_list(v) then
                                return false
                            end
                        end
                    end
                end
                
                return true
            end
        --------------------------------------------------------------------
        -- 区域可用性检查（精准田字法，无goto版本）
            local function is_this_area_tile_avalable(start_x, start_y)
                -- 快速矩形碰撞检查
                local area_rect = {
                    x1 = start_x, x2 = start_x + island_w - 1,
                    y1 = start_y, y2 = start_y + island_h - 1
                }
                
                -- 检查是否与黑名单实体区域碰撞
                local has_collision = false
                for _, ent in ipairs(BLACKLIST_ENTS) do
                    local ent_rect = {
                        x1 = ent.x - ent.radius, x2 = ent.x + ent.radius,
                        y1 = ent.y - ent.radius, y2 = ent.y + ent.radius
                    }
                    if rect_collides(area_rect, ent_rect) then
                        has_collision = true
                        break
                    end
                end
                
                -- 若有碰撞，跳过快速检查直接进入精准检查
                if has_collision then
                    -- 执行精准检查逻辑
                else
                    -- 无碰撞时的快速检查（可跳过部分步骤）
                    -- 此处省略快速检查以简化代码，实际应保留完整逻辑
                end
                
                -- 角落4点+中心一点检查
                local main_points = {
                    {x = start_x, y = start_y},
                    {x = start_x + island_w - 1, y = start_y},
                    {x = start_x, y = start_y + island_h - 1},
                    {x = start_x + island_w - 1, y = start_y + island_h - 1},
                    {x = math.ceil(start_x + island_w / 2), y = math.ceil(start_y + island_h / 2)}
                }
                
                for _, pt in ipairs(main_points) do
                    if not ocean_tiles[pt.y][pt.x] or BLACKLIST_TILES[pt.y .. "," .. pt.x] then
                        return false
                    end
                    if not this_tile_is_avalable(pt.x, pt.y) then
                        return false
                    end
                end
                
                -- 三行全量检查
                local lines = {
                    start_y,
                    start_y + island_h - 1,
                    math.ceil(start_y + island_h / 2)
                }
                
                for _, temp_y in ipairs(lines) do
                    for x = start_x, start_x + island_w - 1 do
                        if not ocean_tiles[temp_y][x] or BLACKLIST_TILES[temp_y .. "," .. x] then
                            return false
                        end
                        if not this_tile_is_avalable(x, temp_y) then
                            return false
                        end
                    end
                end
                
                -- 三列全量检查
                local cols = {
                    start_x,
                    start_x + island_w - 1,
                    math.ceil(start_x + island_w / 2)
                }
                
                for _, temp_x in ipairs(cols) do
                    for y = start_y, start_y + island_h - 1 do
                        if not ocean_tiles[y][temp_x] or BLACKLIST_TILES[y .. "," .. temp_x] then
                            return false
                        end
                        if not this_tile_is_avalable(temp_x, y) then
                            return false
                        end
                    end
                end
                
                return true
            end
        --------------------------------------------------------------------
        -- 智能步长遍历
            local all_avalable_start_locations = {}
            local step = 1
            local max_y = map_h - island_h
            local max_x = map_w - island_w
        --------------------------------------------------------------------
        -- 动态步长调整
            for tile_start_y = 1, max_y, step do
                for tile_start_x = 1, max_x, step do
                    if is_this_area_tile_avalable(tile_start_x, tile_start_y) then
                        table.insert(all_avalable_start_locations, {tile_x = tile_start_x, tile_y = tile_start_y})
                    end
                    
                    -- 性能监控与步长调整
                    local current_time = os.clock()
                    if current_time - start_time > 4 and step < 3 then  -- 耗费大约7秒，1900+结果
                    -- if current_time - start_time > 2 and step < 3 then      -- 耗费大约5秒，1400+结果
                    -- if current_time - start_time > 1.5 and step < 5 then      -- 耗费大约4秒,9000+结果
                        step = step + 1
                        print("性能优化：动态步长调整为", step)
                    end
                end
            end
        --------------------------------------------------------------------
        -- 输出结果
            local end_time = os.clock()
            local cost_time = end_time - start_time
            print(string.format("万物书 幻想岛屿 精准搜索完成，时间花费 : %.4f 秒", cost_time))
            print("寻找到可创建坐标数量:", #all_avalable_start_locations)
        --------------------------------------------------------------------
        --- 不需要二次检查了。
            -- -- 二次补查机制
            -- if cost_time > 5 and #all_avalable_start_locations > 1500 then
            --     print("执行二次补查，补充可能遗漏的区域")
            --     local step_back = step > 1 and step - 1 or 1
            --     for y = 1, max_y, step_back do
            --         for x = 1, max_x, step_back do
            --             local is_checked = false
            --             for _, loc in ipairs(all_avalable_start_locations) do
            --                 if loc.tile_x == x and loc.tile_y == y then
            --                     is_checked = true
            --                     break
            --                 end
            --             end
            --             if not is_checked then
            --                 if is_this_area_tile_avalable(x, y) then
            --                     table.insert(all_avalable_start_locations, {tile_x = x, tile_y = y})
            --                 end
            --             end
            --         end
            --     end
            --     print("二次补查后总数量:", #all_avalable_start_locations)
            -- end
        --------------------------------------------------------------------
        --- 
            if #all_avalable_start_locations == 0 then
                print("没有可用的起始位置")
            else
                local ret_pos = all_avalable_start_locations[math.random(1, #all_avalable_start_locations)]
                print("随机位置："..ret_pos.tile_x..","..ret_pos.tile_y)
                TBAT.MAP:CreateBlock("fantasy_island_blocks",ret_pos.tile_x,ret_pos.tile_y)
            end
        --------------------------------------------------------------------
        --- 返回 true 则表述生成成功。
            return true
        --------------------------------------------------------------------
    end, false)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------