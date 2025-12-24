-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
     豆包AI优化结果，特别快，1秒以内。但是结果只有300多个

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local black_list_tags = {"epic","charactor","cocoon_home","shadecanopy","structure","antlion_sinkhole_blocker","oceanvine","plant"}
    local black_list_prefabs = {}
    local checked_in_black_list = {}

    -- 优化1：缓存黑名单检查结果，减少重复计算
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
---
        TBAT.MAP:SetIslandTaskFn("fantasy_island", function()
            print("万物书 幻想岛屿 开始搜索生成区域")
            
            -- 数据初始化
            local map_w, map_h = TBAT.MAP:GetSize()
            local island_w, island_h = 36, 30
            
            -- 计时器
            local start_time = os.clock()
            
            -- 优化2：预计算海洋区域，减少重复Tile类型检查
            local ocean_tiles = {}
            for y = 1, map_h do
                ocean_tiles[y] = ocean_tiles[y] or {}
                for x = 1, map_w do
                    local tile_type = TBAT.MAP:GetTileData(x, y).tile
                    ocean_tiles[y][x] = TheWorld.Map:IsTileOcean(tile_type)
                end
            end
            
            -- 优化3：合并实体检查逻辑，减少循环次数
            local blacklist_ents = {}
            for k, temp_inst in pairs(Ents) do
                if temp_inst and temp_inst.Transform and inst_in_black_list(temp_inst) then
                    local tile_type, tile_x, tile_y = TBAT.MAP:GetTileByInst(temp_inst)
                    if tile_type and not TheWorld.Map:IsTileOcean(tile_type) then
                        ocean_tiles[tile_y][tile_x] = false
                        blacklist_ents[#blacklist_ents + 1] = {x = tile_x, y = tile_y}
                    end
                end
            end
            
            -- 单个格子可用性检查
            local function this_tile_is_avalable(x, y)
                -- 快速海洋检查
                if not ocean_tiles[y][x] then
                    return false
                end
                
                -- 优化4：减少实体遍历范围，使用更高效的半径检查
                local mid_pt = {x = x, z = y}
                local ents = TheSim:FindEntities(mid_pt.x, 0, mid_pt.z, 30, nil, nil, nil) -- 缩小搜索半径
                
                for k, v in pairs(ents) do
                    if inst_in_black_list(v) then
                        return false
                    end
                end
                
                return true
            end
            
            -- 优化5：使用空间分区思想，预标记不可用区域
            local blocked_tiles = setmetatable({}, {
                __index = function(t, k)
                    t[k] = false
                    return false
                end
            })
            
            for _, ent in ipairs(blacklist_ents) do
                blocked_tiles[ent.y .. "," .. ent.x] = true
            end
            
            -- 区域可用性检查（田字快速查找法优化）
            local function is_this_area_tile_avalable(start_x, start_y, area_w, area_h)
                -- 角落4点+中心一点
                local main_points = {
                    {x = start_x, y = start_y},
                    {x = start_x + area_w - 1, y = start_y},
                    {x = start_x, y = start_y + area_h - 1},
                    {x = start_x + area_w - 1, y = start_y + area_h - 1},
                    {x = math.ceil(start_x + area_w / 2), y = math.ceil(start_y + area_h / 2)}
                }
                
                -- 快速检查关键点
                for _, pt in ipairs(main_points) do
                    if ocean_tiles[pt.y][pt.x] and blocked_tiles[pt.y .. "," .. pt.x] then
                        return false
                    end
                    if not this_tile_is_avalable(pt.x, pt.y) then
                        blocked_tiles[pt.y .. "," .. pt.x] = true
                        return false
                    end
                end
                
                -- 优化6：减少行/列检查次数，使用步长采样
                local sample_step = math.max(1, math.floor(area_w / 10)) -- 动态采样步长
                local lines = {
                    start_y,
                    start_y + area_h - 1,
                    math.ceil(start_y + area_h / 2)
                }
                
                for _, temp_y in ipairs(lines) do
                    for x = start_x, start_x + area_w - 1, sample_step do
                        if not ocean_tiles[temp_y][x] or blocked_tiles[temp_y .. "," .. x] then
                            return false
                        end
                        if not this_tile_is_avalable(x, temp_y) then
                            blocked_tiles[temp_y .. "," .. x] = true
                            return false
                        end
                    end
                end
                
                local cols = {
                    start_x,
                    start_x + area_w - 1,
                    math.ceil(start_x + area_w / 2)
                }
                
                for _, temp_x in ipairs(cols) do
                    for y = start_y, start_y + area_h - 1, sample_step do
                        if not ocean_tiles[y][temp_x] or blocked_tiles[y .. "," .. temp_x] then
                            return false
                        end
                        if not this_tile_is_avalable(temp_x, y) then
                            blocked_tiles[y .. "," .. temp_x] = true
                            return false
                        end
                    end
                end
                
                return true
            end
            
            -- 遍历地图寻找可用区域
            local all_avalable_start_locations = {}
            local max_y = map_h - island_h
            local max_x = map_w - island_w
            
            -- 优化7：分块并行处理（伪并行，通过步长实现）
            local step = 2 -- 处理步长，可根据性能调整
            for tile_start_y = 1, max_y, step do
                for tile_start_x = 1, max_x, step do
                    if is_this_area_tile_avalable(tile_start_x, tile_start_y, island_w, island_h) then
                        table.insert(all_avalable_start_locations, {tile_x = tile_start_x, tile_y = tile_start_y})
                    end
                end
            end
            
            -- 输出结果
            local end_time = os.clock()
            print(string.format("万物书 幻想岛屿 生成区域搜索 时间花费 : %.4f 秒", end_time - start_time))
            print("寻找到可创建坐标数量:", #all_avalable_start_locations)
            
            return false
        end, false)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------