-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    在猪王所在的地方随机生成树
    

    tbat_plant_crimson_maple_tree

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local MAX_TREE_NUM = 20
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 从 table 中随机选取指定数量的不重复元素
    
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主生成任务。
    local function point_test(pt)
        if TheWorld.Map:CanPlantAtPoint(pt.x,0,pt.z) 
            and TBAT.MAP:GetTileAtPoint(pt.x,0,pt.z) == WORLD_TILES[string.upper("deciduous")] --- 地皮符合
            then
            return true
        end
        return false
    end
    local function main_spawn_task(inst)
            -------------------------------------------------------------------
            --- 基础参数
                local x,y,z = inst.Transform:GetWorldPosition()

                local radius = 500
                local radius_delta = 10
                local min_radius = 50
            -------------------------------------------------------------------
            ---
                local current_trees = TheSim:FindEntities(x, 0, z, radius, {"tbat_plant_crimson_maple_tree"})
                local need_spawn_num = MAX_TREE_NUM - #current_trees
                if need_spawn_num <= 0 then
                    print("秋风树已经在范围内充足",inst,#current_trees)
                    return
                end
                print("需要生成秋风树数量:",need_spawn_num)
            -------------------------------------------------------------------
            --- 寻找合适坐标
                local avalable_points = {}
                while radius > min_radius do
                    local points = TBAT.FNS:GetSurroundPoints({
                        target = Vector3(x,0,z),
                        range = radius,
                        num = radius*5
                    })
                    radius = radius - radius_delta
                    for i, point in ipairs(points) do
                        if point_test(point) then
                            table.insert(avalable_points,point)
                        end
                    end
                end
            -------------------------------------------------------------------
            ----
                local ret_points = TBAT.FNS:GetRandomDiffrenceValuesFromTable(avalable_points,need_spawn_num)
                for i, point in ipairs(ret_points) do
                    TheWorld:DoTaskInTime(i,function()
                        local tree = SpawnPrefab("tbat_plant_crimson_maple_tree")
                        tree.Transform:SetPosition(point.x,point.y,point.z)                        
                    end)
                end
            -------------------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- pigking
    local pigkings = {}
    AddPrefabPostInit("pigking",function(inst)
        if not TheWorld.ismastersim or TheWorld:HasTag("cave") then
            return
        end
        pigkings[inst] = true
    end)
    local function GetAllPigKings()
        local ret = {}
        for k, v in pairs(pigkings) do
           if k:IsValid() then
                table.insert(ret, k)
           end
        end
        return ret
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





local function tree_spawn_task(inst)
    local list = GetAllPigKings()
    for k, v in pairs(list) do
        main_spawn_task(v)
    end
end
local function tree_daily_spawn_task(inst)
    if TheWorld.state.cycles % 10 == 0 then
        tree_spawn_task(inst)
    end
end

AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim or TheWorld:HasTag("cave") then
        return
    end
    inst:WatchWorldState("cycles",tree_daily_spawn_task)
    inst:DoTaskInTime(10,tree_spawn_task)    
end)
