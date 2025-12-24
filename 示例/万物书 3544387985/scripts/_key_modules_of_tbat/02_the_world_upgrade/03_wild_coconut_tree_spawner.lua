-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    初始在猴子岛屿沙滩地皮上面生成三阶段的4到5棵【清甜椰子树】
    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local MAX_TREE_NUM = 5
    local MIN_TREE_NUM = 4
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 从 table 中随机选取指定数量的不重复元素
    
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function main_spawn_task(inst)
        print("info 野生椰子树 生成任务开始",inst)
        if TheWorld.components.tbat_data:Add("wild_coconut_tree_spawned.num",0) >= MIN_TREE_NUM then
            print("info 野生椰子树 已经生成够数量，任务退出",inst)
            return
        end
        local x,y,z = inst.Transform:GetWorldPosition()
        local max_num = math.random(MIN_TREE_NUM,MAX_TREE_NUM)
        local current_num = 0
        local radius = 40
        local min_radius = 6
        local ret_avalable_points = {}
        while true do
            local points = TBAT.FNS:GetSurroundPoints({
                target = Vector3(x,y,z),
                range = radius,
                num = radius*5
            }) 
            for i,pt in ipairs(points) do
                if TheWorld.Map:CanPlantAtPoint(pt.x,0,pt.z) then
                    table.insert(ret_avalable_points,pt)
                end
            end
            radius = radius - 3
            if radius <= min_radius then
                break
            end
        end
        print("info 野生椰子树 共找到可生成位置:",#ret_avalable_points)
        local avalable_points = TBAT.FNS:GetRandomDiffrenceValuesFromTable(ret_avalable_points,max_num)
        print("info 野生椰子树 随机到位置数量:",#avalable_points)
        for i,pt in ipairs(avalable_points) do
            local tree = SpawnPrefab("tbat_plant_coconut_tree")
            TheWorld.components.tbat_data:Add("wild_coconut_tree_spawned.num",1)
            tree.Transform:SetPosition(pt.x,0,pt.z)
            tree.components.growable:SetStage(4)
        end
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





-- local function spawn_task(inst)
--     local queen = TheSim:FindFirstEntityWithTag("monkeyqueen")
--     if not (queen and queen:HasTag("monkey") and queen:HasTag("shelter") and queen:HasTag("trader") ) then
--         return
--     end
--     if TheWorld.components.tbat_data:Add("wild_coconut_tree_spawned.num",0) >= MIN_TREE_NUM then
--         return
--     end
--     TheWorld.components.tbat_com_special_timer_for_theworld:AddOneTimeTimer(main_spawn_task,queen)
-- end
-- AddPrefabPostInit("world",function(inst)
--     if not TheWorld.ismastersim or TheWorld:HasTag("cave") then
--         return
--     end
--     inst:DoTaskInTime(3,spawn_task)
-- end)
AddPrefabPostInit("monkeyqueen",function(inst)
    if not TheWorld.ismastersim then
        return
    end    
    inst:ListenForEvent("entitywake",main_spawn_task)
    inst:ListenForEvent("tbat_event.spawn_wild_coconut_tree",main_spawn_task)
end)