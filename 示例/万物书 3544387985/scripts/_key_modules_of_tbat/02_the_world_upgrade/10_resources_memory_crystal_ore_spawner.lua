-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主生成任务。
    local function main_spawn_task(inst)
        -------------------------------------------------------------------
        ---
            if TheWorld.components.tbat_data:Get("resources_memory_crystal_ore") then
                return
            end
        -------------------------------------------------------------------
        --- 寻找矿区
            local prefabs = {
                ["rock1"] = 3,
                ["rock2"] = 3,
                ["spiderden"] = 1,
                ["spiderden_2"] = 1,
                ["spiderden_3"] = 1,
            }
            local pt = TBAT.FNS:PrefabAreaCenterSearch(80,prefabs)
        -------------------------------------------------------------------
        ---
            if pt == nil then
                return
            end
        -------------------------------------------------------------------
        --- 寻找可用位置
            local radius = 80
            local test_inst = SpawnPrefab("tbat_resources_memory_crystal_ore_core")
            local avalable_points = {}
            while radius > 0 do
                local temp_points = TBAT.FNS:GetSurroundPoints({
                    target = pt,
                    range = radius,
                    num = radius*4*5
                })
                for k, pt in pairs(temp_points) do
                    if TheWorld.Map:CanDeployAtPoint(pt,test_inst) then
                        table.insert(avalable_points,pt)
                    end
                end
                radius = radius - 2
            end
            test_inst:Remove()
            if #avalable_points == 0 then
                return
            end
            local points = TBAT.FNS:GetRandomDiffrenceValuesFromTable(avalable_points, math.random(6,8))
            for k, pt in pairs(points) do 
                SpawnPrefab("tbat_resources_memory_crystal_ore_3").Transform:SetPosition(pt.x,pt.y,pt.z)
            end
        -------------------------------------------------------------------
        ---
            TheWorld.components.tbat_data:Set("resources_memory_crystal_ore",true)
            print("[TBAT] +++ 创建[记忆水晶矿源] 成功")
        -------------------------------------------------------------------
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

AddPrefabPostInit("world",function(inst)
    if not TheWorld.ismastersim or TheWorld:HasTag("cave") then
        return
    end
    inst:DoTaskInTime(10 + math.random(10),main_spawn_task)
end)
