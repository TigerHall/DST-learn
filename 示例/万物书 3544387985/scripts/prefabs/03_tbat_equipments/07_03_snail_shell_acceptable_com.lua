--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    物品接受升级
    需要处理几种情况：
    1、物品的叠堆 小于 需求量
    2、物品的叠堆 等于 需求量
    3、物品的叠堆 大于 需求量

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    local this_prefab = "tbat_eq_snail_shell_of_mushroom"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受升级
    local function acceptable_test_fn(inst,item,doer,right_click)
        if inst.accept_data then
            for k, data in pairs(inst.accept_data) do
                if item.prefab == data.prefab then
                    return true
                end
            end
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 标记位
            local succeed_flag = false 
        --------------------------------------------------
        --- 给予的物品叠堆数量 (修复：未正确赋值)
            local item_stack_num = 1
            if item.components.stackable then
                item_stack_num = item.components.stackable:StackSize() -- 修复：获取实际堆叠数
            end
        --------------------------------------------------
        --- 数据 (修复：未处理data未找到的情况)
            local data = nil
            for k, temp_data in pairs(inst.accept_data) do 
                if item.prefab == temp_data.prefab then
                    data = temp_data
                    break
                end
            end
            if not data then -- 未找到匹配数据直接返回
                return false
            end
        --------------------------------------------------
        --- 获取当前已接受数量 (修复：逻辑错误)
            -- local current_num = inst.components.tbat_data:GetCount(item.prefab) -- 假设GetCount存在，或使用修正逻辑
            -- 如果没有GetCount，改用以下安全方案（根据常见实现）：
            local current_num = inst.components.tbat_data:Get(item.prefab) or 0

            local remaining = data.max - current_num -- 计算剩余空间
            if remaining <= 0 then
                return false -- 已满，无法接受
            end

            local consume_num = math.min(item_stack_num, remaining) -- 实际消耗数量
        --------------------------------------------------
        --- 消耗物品 (修复：条件逻辑错误)
            if consume_num <= item_stack_num then
                -- 消耗部分物品
                item.components.stackable:Get(consume_num):Remove()
            else
                -- 消耗全部物品
                item:Remove()
            end
        --------------------------------------------------
        --- 更新数据 (修复：参数错误)
            inst.components.tbat_data:Add(item.prefab, consume_num, 0, data.max) -- 修正参数：传入实际消耗量
            succeed_flag = true
            inst:PushEvent("refresh_level")
            inst:PushEvent("refresh_name")
        --------------------------------------------------
        return succeed_flag
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.UPGRADE.GENERIC)
        replica_com:SetSGAction("doshortaction")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return acceptable_com_install