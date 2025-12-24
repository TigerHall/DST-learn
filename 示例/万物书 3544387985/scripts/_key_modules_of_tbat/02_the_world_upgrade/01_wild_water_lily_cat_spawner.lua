-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    野生的 睡莲猫猫 刷新。

    watertree_pillar

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- watertree_pillar 大型水中木
    local all_big_trees_ids = {}
    AddPrefabPostInit("watertree_pillar",function(inst)
        if not TheWorld.ismastersim then
            return
        end
        all_big_trees_ids[inst] = true
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- debug 检查
    if TBAT.DEBUGGING then
        local all_cats = {}
        AddPrefabPostInit("tbat_turf_water_lily_cat",function(inst)
            if not TheWorld.ismastersim then
                return
            end
            all_cats[inst] = true
        end)
        AddPrefabPostInit("world",function(inst)
            if not TheWorld.ismastersim then
                return
            end
            inst:ListenForEvent("get_all_wild_water_lily_cat",function(_,callback)
                if type(callback) ~= "table" then
                    return
                end
                local new_table = {}
                for cat,flag in pairs(all_cats) do
                    if cat and cat:IsValid() and cat:HasTag("dig_block") then
                        table.insert(callback,cat)
                        new_table[cat] = true
                    end
                end
                all_cats = new_table
            end)
        end)
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 全局标记/参数
    local spawn_task_started_in_this_archive = false
    local MAX_WILD_NUM = 18
    local CURRENT_SPAWNED_NUM = 0
    local function spawn_check_task(inst)
        if not spawn_task_started_in_this_archive then
            return
        end
        if CURRENT_SPAWNED_NUM > 0 then
            TheNet:Announce("【 万物书 】生成【野生睡莲猫猫】数量 "..tostring(CURRENT_SPAWNED_NUM).."  ,本应生成数量： "..tostring(MAX_WILD_NUM).."  ")
        else
            TheNet:Announce("【 万物书 】生成【野生睡莲猫猫】出现错误，应该是遭遇了模组兼容性问题，无法找到合适的位置生成")
        end
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 开始刷新
    local function spawn_wild_plats(ret_points)
        --- 分阶段计时生成，避免瞬间大量生成造成的可能闪退
        if #ret_points > 0 then
            print("fake error : 开始进行野生睡莲猫猫 生成")
            for k, pt in pairs(ret_points) do
                TheWorld:DoTaskInTime(k*2,function()                        
                        local plant = SpawnPrefab("tbat_turf_water_lily_cat")
                        local cmd_table = { 
                            pt = pt,
                            stop_grow = true,       --- 屏蔽生长
                            dig_block = true,       --- 屏蔽挖掘
                            -- success = false         --- 回调
                        }
                        plant:PushEvent("deploy",cmd_table)
                        if cmd_table.success then
                            print("fake error : 野生的睡莲猫猫 生成",k,plant)
                            CURRENT_SPAWNED_NUM = CURRENT_SPAWNED_NUM + 1
                        end
                end)
            end
        end
    end
    local function start_water_lily_cat_task(inst)
        if inst.components.tbat_data:Get("wild_water_lily_cat_spawned") then
            return
        end
        inst.components.tbat_data:Set("wild_water_lily_cat_spawned",true)
        spawn_task_started_in_this_archive = true
        ------------------------------------------------------------------------
        ---
            local all_trees = {}
            for tree,flag in pairs(all_big_trees_ids) do
                table.insert(all_trees,tree)
            end
            if #all_trees == 0 then
                return
            end
        ------------------------------------------------------------------------
        --- 开始扫描
            local current_wild_num = 0
            local test_num = 10000
            local ret_points = {}
            while test_num > 0 do
                if current_wild_num >= MAX_WILD_NUM then
                    spawn_wild_plats(ret_points)
                    return
                end
                for k, tree in pairs(all_trees) do
                    if current_wild_num >= MAX_WILD_NUM then
                        spawn_wild_plats(ret_points)
                        return
                    end
                    -- local x,y,z = tree.Transform:GetWorldPosition()
                    -----------------------------------------------------------
                    ---
                        local radius = 15
                        local radius_delta = 2
                        while radius > 4 do
                            local points = TBAT.FNS:GetSurroundPoints({
                                target = tree,
                                range = radius,
                                num = radius*2*4
                            })
                            local ret_pt = points[math.random(#points)]

                            local plant = SpawnPrefab("tbat_turf_water_lily_cat")
                            local cmd_table = { 
                                pt = ret_pt,
                                stop_grow = true,       --- 屏蔽生长
                                dig_block = true,       --- 屏蔽挖掘
                                only_test = true,       --- 只是测试
                                -- success = false         --- 回调
                            }
                            plant:PushEvent("deploy",cmd_table)
                            if cmd_table.success then
                                current_wild_num = current_wild_num + 1
                                print("fake error : 野生睡莲猫猫 寻找到合适坐标",current_wild_num,ret_pt)
                                table.insert(ret_points,ret_pt)
                                break
                            end
                            radius = radius - radius_delta
                        end
                    -----------------------------------------------------------
                end
                test_num = test_num - 1
            end
        ------------------------------------------------------------------------
    end
    AddPrefabPostInit("world",function(inst)
        if not TheWorld.ismastersim then
            return
        end
        if TheWorld:HasTag("cave") then
            return
        end
        if inst.components.tbat_data == nil then
			inst:AddComponent("tbat_data")
		end
        inst:DoTaskInTime(10,start_water_lily_cat_task)
        -- inst:DoTaskInTime(60,spawn_check_task)
    end)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------