--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    用来处理 可叠加物品 和 不可叠加物品 给目标容器 放置 inst 的问题

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    ---- 通义AI 优化过的
    function TBAT.FNS:GiveItemByPrefab(inst, prefab, num)
        num = math.floor(num or 1)
        if num <= 0 then return end
        
        if not PrefabExists(prefab) then
            print("Error in TBAT.FNS:GiveItemByPrefab : ",inst,prefab,num)
            return
        end

        local container_com = inst.components.inventory or inst.components.container
        if not container_com then
            print("Error in TBAT.FNS:GiveItemByPrefab - Inst does not have an inventory or container component. ",inst)
            return
        end

        local first_item = SpawnPrefab(prefab)
        if not first_item then return end

        -- 非堆叠物品直接分批添加
        if not first_item.components.stackable then
            container_com:GiveItem(first_item)
            for i = 1, num - 1 do
                container_com:GiveItem(SpawnPrefab(prefab))
            end
            return
        end

        local max_stack_num = first_item.components.stackable.maxsize
        local remaining = num

        -- 处理首堆叠
        local first_stack_size = math.min(remaining, max_stack_num)
        first_item.components.stackable:SetStackSize(first_stack_size)
        container_com:GiveItem(first_item)
        remaining = remaining - first_stack_size

        -- 处理剩余堆叠
        while remaining > 0 do
            local new_item = SpawnPrefab(prefab)
            local stack_size = math.min(remaining, max_stack_num)
            new_item.components.stackable:SetStackSize(stack_size)
            container_com:GiveItem(new_item)
            remaining = remaining - stack_size
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- function TBAT.FNS:GiveItemByPrefab(inst,prefab,num)
    --     num = math.floor( num or 1 )
    --     if num <= 0 then return end
    --     if not PrefabExists(prefab) then
    --         print("Error in TBAT.FNS:GiveItemByPrefab",inst,prefab,num)
    --         return
    --     end

    --     local container_com = inst.components.inventory or inst.components.container


    --     local first_item = SpawnPrefab(prefab)
    --     if first_item.components.stackable == nil then
    --         container_com:GiveItem(first_item)
    --         for i = 1, num - 1 , 1 do
    --             container_com:GiveItem(SpawnPrefab(prefab))
    --         end
    --         return
    --     end

    --     local max_stack_num = first_item.components.stackable.maxsize
    --     if num <= max_stack_num then
    --         first_item.components.stackable:SetStackSize(num)
    --         container_com:GiveItem(first_item)
    --         return
    --     end

    --     first_item.components.stackable:SetStackSize(max_stack_num)
    --     container_com:GiveItem(first_item)
    --     num = num - max_stack_num

    --     ---- 循环



    -- end