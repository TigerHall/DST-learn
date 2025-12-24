-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    TBAT.MAP = Class()
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- GetSize
    function TBAT.MAP:GetSize()
        return TheWorld.Map:GetSize()
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 输入地块的 XY 得到这个地块中心的 世界坐标Vector3() -- 默认每个格子为 4x4距离
    function TBAT.MAP:GetWorldPointByTileXY(x,y,map_width,map_height)
            if map_width == nil or map_height == nil then
                map_width,map_height = TheWorld.Map:GetSize()
            end
            local ret_x = x - map_width/2
            local ret_z = y - map_height/2
            return Vector3(ret_x*TILE_SCALE,0,ret_z*TILE_SCALE)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 输入地块的坐标，得到tile 的XY
    function TBAT.MAP:GetTileXYByWorldPoint(x,y,z)
        return TheWorld.Map:GetTileCoordsAtPoint(x,0,z)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 获取地皮中点 ,返还 x,y,z
    function TBAT.MAP:GetTileCenterPoint(x,y,z)
        -- local tile_x,tile_y = self:GetTileXYByWorldPoint(x,y,z)
        -- return TheWorld.Map:GetTileCenterPoint(tile_x,tile_y)
        return TheWorld.Map:GetTileCenterPoint(x,y,z)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 输入地块的坐标，得到tile 的类型
    function TBAT.MAP:GetTileAtPoint(x,y,z)
        return TheWorld.Map:GetTileAtPoint(x,0,z)
    end
    function TBAT.MAP:GetTileIndexAtPoint(x,y,z)
        local tile = self:GetTileAtPoint(x,y,z)
        for index,num in pairs(WORLD_TILES) do
            if num == tile then
                return index
            end
        end
        return "DIRT"
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 地皮拥有的tag
    function TBAT.MAP:HasTagInPoint(x,y,z,tag)
        local node_index = TheWorld.Map:GetNodeIdAtPoint(x, 0, z) or 0                
        local node = TheWorld.topology.nodes[node_index] or {}
        local tags = node.tags or {}
        for k, tag in pairs(tags) do
            if tag == tag then
                return true
            end
        end
        return false
    end
    function TBAT.MAP:GetAllTagsInPoint(x,y,z)
        local node_index = TheWorld.Map:GetNodeIdAtPoint(x, 0, z) or 0
        local node = TheWorld.topology.nodes[node_index] or {}
        local temp =  node.tags or {}
        local ret = {}
        local ret_index = {}
        for k, tag in pairs(temp) do
            if k and tag then
                table.insert(ret,tag)
                ret_index[tag] = true
            end
        end
        return ret,ret_index
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- set tile at point
    function TBAT.MAP:SetTileWithIndexAtPoint(x,y,z,tile)
        if WORLD_TILES[tile] then
            local tile_x,tile_y = self:GetTileXYByWorldPoint(x,y,z)
            TheWorld.Map:SetTile(tile_x,tile_y,WORLD_TILES[tile])
        end
    end
    local WORLD_TILES_IDX = nil
    local is_world_tile = function(index)
        if WORLD_TILES_IDX == nil then
            WORLD_TILES_IDX = {}
            for k, v in pairs(WORLD_TILES) do
                WORLD_TILES_IDX[v] = k
            end
        end
        return WORLD_TILES_IDX[index] ~= nil
    end
    function TBAT.MAP:SetTileAtPoint(x,y,z,index)
        if not is_world_tile(index) then
            return
        end
        local tile_x,tile_y = self:GetTileXYByWorldPoint(x,y,z)
        TheWorld.Map:SetTile(tile_x,tile_y,index)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 锚点装饰器
    local all_anchors_decorate_fn = {}
    function TBAT.MAP:AddAnchorDecorateTask(prefab,task,fn)
        if type(prefab) == "string" and type(task) == "string" and type(fn) == "function" then
            all_anchors_decorate_fn[prefab] = all_anchors_decorate_fn[prefab] or {}
            -- all_anchors_decorate_fn[prefab][task] = fn
            table.insert(all_anchors_decorate_fn[prefab],{task = task,fn = fn})
        end
    end
    function TBAT.MAP:GetAnchorDecorateTasks(prefab)
        if all_anchors_decorate_fn[prefab] then
            return all_anchors_decorate_fn[prefab]
        end
        return {}
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 创建唯一的 锚点
    function TBAT.MAP:CreateUniqueAnchor(prefab,x,y,z)
        local ents = TheSim:FindEntities(x,y,z, 4)
        for k, v in pairs(ents) do
            if v.prefab == prefab then
                print("Error [TBAT] 创建锚点失败:已经有重复的",prefab)
                return v
            end
        end
        local inst = SpawnPrefab(prefab)
        inst.Transform:SetPosition(x,y,z)
        return inst
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- island create fn 岛屿创建函数
    local island_task_fns = {}
    function TBAT.MAP:SetIslandTaskFn(island_id,fn,cave_flag)
        island_task_fns[island_id] = {
            fn = fn,
            cave_flag = cave_flag or false,
        }
    end
    function TBAT.MAP:RunIslandTaskFns()
        for island_id, _table in pairs(island_task_fns) do
            local cave_flag = _table.cave_flag
            local fn = _table.fn
            if TheWorld.components.tbat_data:Get(island_id) then
                
            else
                if fn() then
                    TheWorld.components.tbat_data:Set(island_id,true)
                end
            end
        end
    end
    function TBAT.MAP:HasIslandCreateTask()
        for island_id, _table in pairs(island_task_fns) do
            local cave_flag = _table.cave_flag
            local fn = _table.fn
            if not TheWorld.components.tbat_data:Get(island_id) and TheWorld:HasTag("cave") == cave_flag then
                return true
            end
        end
        return false
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- blocks 地图块
    local blocks = {}
    function TBAT.MAP:AddBlock(name,fn)
        blocks[name] = fn
    end
    function TBAT.MAP:CreateBlock(name,tile_start_x,tile_start_y)
        if blocks[name] then
            blocks[name](tile_start_x,tile_start_y)
        end
        blocks[name] = nil
    end
    function TBAT.MAP:ClearAllBlocks()
        -- blocks = {}
        -- TheWorld:PushEvent(,data)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[ 地皮相关

    TheWorld.Map:GetTileAtPoint(x,y,z)

    地皮数据：
        4  - 空的陆地。 WORLD_TILES["DIRT"]
        5  - 黄草地  WORLD_TILES[string.upper("savanna")]  -- item_prefab = "turf_savanna"

        260 - 码头  WORLD_TILES["MONKEY_DOCK"]

                    -- local rd1 = WORLD_TILES[string.upper("fwd_in_pdt_turf_cobbleroad")]
                    local carp = 11 --- 牛毛地毯
                    local redt = 30 --- 落叶林地毯
                    local fost = 7  --- 森林地皮
                    local cobb = WORLD_TILES[string.upper("fwd_in_pdt_turf_cobbleroad")]
                    local lawn = WORLD_TILES[string.upper("fwd_in_pdt_turf_grasslawn")]
                    local snak = WORLD_TILES[string.upper("fwd_in_pdt_turf_snakeskin")]

    ]]--
    local function get_tile_by_item_prefab(prefab)
        local index = string.upper(prefab:match("^turf_(.*)") or "DIRT")
        return WORLD_TILES[index] or WORLD_TILES["DIRT"]
    end
    function TBAT.MAP:GetTileIndexByItemPrefab(prefab)
        return get_tile_by_item_prefab(prefab)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- tile_for_inst
    local tile_for_inst = {}
    local function set_tile_for_inst(inst,tile_type,tile_x,tile_y)
        tile_for_inst[inst] = {
            tile = tile_type,
            tile_x = tile_x,
            tile_y = tile_y,
        }
    end
    function TBAT.MAP:GetTileByInst(inst)
        if tile_for_inst[inst] then
            return tile_for_inst[inst].tile,tile_for_inst[inst].tile_x,tile_for_inst[inst].tile_y
        end
        return nil
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 基于锚点和数据，装修岛屿
    function TBAT.MAP:DecorateIslandByAnchor(data,x,y,z)
        ------------------------------------------------------
        --- 示例
            -- data = {
            --     [prefab_or_skin ] = {
            --         prefab = "driftwood_tall" ,
            --         points = { Vector3(0,0,0),Vector3(1,0,1) },  --- 根据点个数生成对应数量的目标
            --         points_str = "",                             --- 【可选】坐标的 json 格式。
            --         pt = Vector3(0,0,0),                         --- 【可选】单个的时候可选这个。
            --         rotation = 0,                                --- 【可选】旋转角度
            --         fn = function(inst) end,                     --- 【可选】执行特殊函数
            --         tbat_skin = nil,                             --- 【可选】本MOD的物品皮肤皮肤
            --         has_tbat_skin = true,                         --- 【可选】以index 为皮肤名字。
            --         mirror = nil,                                --- 【可选】镜像
            --         scale = {1,1,1},                             --- 【可选】缩放
            --         health_percent = nil,                        --- 【可选】生命百分比
            --     },
            -- }
        ------------------------------------------------------
        ---
            if type(data) == "string" then
                data = json.decode(data)
            end
        ------------------------------------------------------
        ---
            for prefab_or_skin, single_data in pairs(data) do
                local prefab = single_data.prefab
                if single_data.points == nil and single_data.points_str then
                    single_data.points = json.decode(single_data.points_str)
                end
                single_data.points = single_data.points or {}
                if single_data.pt then
                    table.insert(single_data.points, single_data.pt)
                end
                for k, pt in pairs(single_data.points) do
                    local inst = SpawnPrefab(prefab)
                    inst.Transform:SetPosition(x+pt.x,0,z+pt.z)
                    if single_data.rotation then
                        inst.Transform:SetRotation(single_data.rotation)
                    end
                    if inst.components.tbat_com_skin_data then
                        if single_data.tbat_skin then 
                            inst.components.tbat_com_skin_data:SetCurrent(single_data.tbat_skin)
                        elseif single_data.has_tbat_skin then
                            inst.components.tbat_com_skin_data:SetCurrent(prefab_or_skin)
                        end                                
                    end
                    if single_data.fn then
                        pcall(single_data.fn,inst)
                    end
                    if inst.components.tbat_com_universal_baton_data then
                        if single_data.mirror then
                            inst.components.tbat_com_universal_baton_data:Mirror()
                        end
                        if type(single_data.scale) == "table" and single_data.scale[1] and single_data.scale[2] then
                            inst.components.tbat_com_universal_baton_data:SetScale(unpack(single_data.scale))
                        end
                    end
                    if single_data.health_percent and inst.components.health then
                        inst.components.health:SetPercent(single_data.health_percent)
                    end
                end            
            end
        ------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- init
    TBAT.MAP.data = {}
                                                -- TBAT.MAP.data[y][x] = { 
                                                --                 tile = 1,
                                                --                 ents = {}, 
                                                --                 tile_x = 0,tile_y = 0,
                                                --                 mid_pt = Vector3()
                                                --
                                                -- }
    function TBAT.MAP:GetTileData(tile_x,tile_y)
        if self.data[tile_y] and self.data[tile_y][tile_x] then
            return self.data[tile_y][tile_x]
        end
        return nil
    end
    function TBAT.MAP:DataInit()
        --------------------------------------------------------------------------
        --- 地图尺寸
            local width,height = self:GetSize()
        --------------------------------------------------------------------------
        --- 初始化数据
            for tile_y = 1,height do
                for tile_x = 1,width do
                    self.data[tile_y] =  self.data[tile_y] or {}
                    self.data[tile_y][tile_x] = self.data[tile_y][tile_x] or {}

                    self.data[tile_y][tile_x].tile_x = tile_x
                    self.data[tile_y][tile_x].tile_y = tile_y
                    self.data[tile_y][tile_x].tile = TheWorld.Map:GetTile(tile_x,tile_y)
                    self.data[tile_y][tile_x].ents = {}
                    self.data[tile_y][tile_x].mid_pt = self:GetWorldPointByTileXY(tile_x,tile_y,width,height)

                end
            end
        --------------------------------------------------------------------------
        --- 遍历记录所有ents 得到每个tile 里的 ents
            for k, temp_inst in pairs(Ents) do
                if temp_inst.prefab and temp_inst.Transform then
                    local x,y,z = temp_inst.Transform:GetWorldPosition()
                    local tile_x,tile_y = self:GetTileXYByWorldPoint(x,y,z)
                    if self.data[tile_y] and self.data[tile_y][tile_x] then
                        table.insert(self.data[tile_y][tile_x].ents,temp_inst)
                        set_tile_for_inst(temp_inst,TheWorld.Map:GetTile(tile_x,tile_y),tile_x,tile_y)
                    end
                end
            end
        --------------------------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主入口

    TBAT:AddTheWorldRealOnPostInitFn(function()
        TBAT:AddOnPostInitFn(function(self)            
        --------------------------------------------------------------------------
        ---             
        --------------------------------------------------------------------------
        --- 
            -- if TheWorld:HasTag("cave") then
            --     return
            -- end
            if not TBAT.MAP:HasIslandCreateTask() then
                self:ClearAllBlocks()
                return
            end
        --------------------------------------------------------------------------
        --- 
            print("万物书：检测到需要创建岛屿，启动岛屿创建流程")            
            self:DataInit()
        --------------------------------------------------------------------------
        ---
            self:RunIslandTaskFns()
            self:ClearAllBlocks()
        --------------------------------------------------------------------------
        end,TBAT.MAP)
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------