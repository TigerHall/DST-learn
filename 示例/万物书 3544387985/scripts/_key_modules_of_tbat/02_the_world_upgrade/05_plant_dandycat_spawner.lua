-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    在猪王所在的地方随机生成树
    

    tbat_plant_crimson_maple_tree

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local MAX_TREE_NUM = 3
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主生成任务。
    local function point_test(pt)
        if TheWorld.Map:CanPlantAtPoint(pt.x,0,pt.z) then
            return true
        end
        return false
    end
    local function main_spawn_task(inst)
            -------------------------------------------------------------------
            --- 基础参数
                local x,y,z = inst.Transform:GetWorldPosition()

                local radius = 20
                local radius_delta = 0.5
                local min_radius = 4
            -------------------------------------------------------------------
            ---
                local current_trees = TheSim:FindEntities(x, 0, z, radius, {"tbat_plant_dandycat"})
                local need_spawn_num = MAX_TREE_NUM - #current_trees
                if need_spawn_num <= 0 then
                    return
                end
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
                        local tree = SpawnPrefab("tbat_plant_dandycat")
                        tree:PushEvent("on_plant",{
                            pt = point,
                            wild = true,
                        })
                    end)
                end
            -------------------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 目标节点库
    local spawn_base_inst_list = {}
    AddPrefabPostInit("beequeenhive",function(inst)
        if not TheWorld.ismastersim or TheWorld:HasTag("cave") then
            return
        end
        spawn_base_inst_list[inst] = true
    end)
    local function GetAllSpawnBase()
        local ret = {}
        for k, v in pairs(spawn_base_inst_list) do
           if k:IsValid() then
                table.insert(ret, k)
           end
        end
        return ret
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function tree_spawn_task(inst)
    local list = GetAllSpawnBase()
    for k, v in pairs(list) do
        main_spawn_task(v)
    end
end
AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim or TheWorld:HasTag("cave") then
        return
    end
    inst:DoTaskInTime(10,tree_spawn_task)    
end)
