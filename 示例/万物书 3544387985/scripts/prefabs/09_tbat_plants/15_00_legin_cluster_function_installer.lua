--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    棱镜变种植物的 簇 功能。

    主产物数量为簇栽等级*1，副产物为簇栽等级*0.4

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数组
    local string_index = "tbat_farm_plant_legin_cluster_sys"
    local MAX_CLUSTER_LEVEL = 99
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受。
    local function acceptable_test_fn(inst,item,doer,right_click)
        return item.prefab == inst.seed_prefab
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 等级
            local current_level = inst.components.tbat_data:Get("cluster") or 1
        --------------------------------------------------
        --- 成熟阶段不给添加
            local current_stage = inst.components.growable:GetStage()
            if current_stage >= 4 then
                return false,"accept_fail"
            end
        --------------------------------------------------
        ---
            local can_level_up_num = MAX_CLUSTER_LEVEL - current_level
            if can_level_up_num <= 0 then
                return false,"accept_fail.max"
            end
        --------------------------------------------------
        --- 不能叠堆物品
            if item.components.stackable == nil then
                item:Remove()
                inst.components.tbat_data:Add("cluster",1,1,MAX_CLUSTER_LEVEL)
                inst:PushEvent("cluseter_update")
                inst:PushEvent("pick_loot_force_update")
                return true
            end
        --------------------------------------------------
        --- 叠堆物品
            local stack_num = item.components.stackable:StackSize()
            if stack_num <= can_level_up_num then
                item:Remove()
                inst.components.tbat_data:Add("cluster",stack_num,1,MAX_CLUSTER_LEVEL)
                inst:PushEvent("cluseter_update")
                inst:PushEvent("pick_loot_force_update")
            else
                item.components.stackable:SetStackSize(stack_num - can_level_up_num)
                inst.components.tbat_data:Add("cluster",can_level_up_num,1,MAX_CLUSTER_LEVEL)
                inst:PushEvent("cluseter_update")
                inst:PushEvent("pick_loot_force_update")
            end
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(string_index,TBAT:GetString2(string_index,"action"))
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
--- 等级系统
    local function level_init(inst)
        --- 初始化等级为 1
        if inst.components.tbat_data:Add("cluster",0) == 0 then
            inst.components.tbat_data:Set("cluster",1)
        end
        inst:PushEvent("cluseter_update")
    end
    local clusted_scale = 1.1
    local function level_update_fn(inst)
        local current_level = inst.components.tbat_data:Get("cluster") or 1
        if current_level > 1 then
            inst.AnimState:SetScale(clusted_scale,clusted_scale,clusted_scale)
        else
            inst.AnimState:SetScale(1,1,1)
        end
        inst.__cluster_num:set(current_level)
    end
    local function loots_update_fn(inst,callback)
        -----------------------------------------
        --[[
            掉落列表修改。
            仅限于匹配的loot cmd data 结构。
            只能一主一副，前者是主。
        ]]--
        -----------------------------------------
        if type(callback) ~= "table" then
            return
        end
        if callback.stage ~= 4 then
            return
        end
        local loot_cmd_data = callback.loot_cmd_data or {}
        local main_item_data = loot_cmd_data[1] or {}
        local sub_item_data = loot_cmd_data[2] or {}

        local main_item_prefab = main_item_data[1]
        local main_item_num = main_item_data[2] or 1

        local sub_item_prefab = sub_item_data[1]
        local sub_item_num = sub_item_data[2] or 1

        if main_item_prefab == nil and sub_item_prefab == nil then
            return
        end

        local level = inst.components.tbat_data:Get("cluster") or 1
        if level <= 1 then
            return
        end
        local new_loot = {}
        if main_item_prefab and PrefabExists(main_item_prefab) then
            main_item_num = main_item_num * level
            for i = 1, main_item_num, 1 do
                table.insert(new_loot,main_item_prefab)
            end
        end
        if sub_item_prefab and PrefabExists(sub_item_prefab) then
            sub_item_num = math.floor(sub_item_num * level * 0.4)
            for i = 1, sub_item_num, 1 do
                table.insert(new_loot,sub_item_prefab)
            end
        end
        callback.new_loot = new_loot
    end
    local function level_sys_install(inst)
        inst:DoTaskInTime(0,level_init)
        inst:ListenForEvent("cluseter_update",level_update_fn)
        inst:ListenForEvent("on_pick_loots_update",loots_update_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 显示指示
    local function name_change_fn(inst)
        local level = inst.__cluster_num:value()
        local origin_name = STRINGS.NAMES[string.upper(inst.prefab)]
        local new_name = origin_name.."\n"..level.." / "..MAX_CLUSTER_LEVEL .."  ".. TBAT:GetString2(string_index,"display")
        inst.name = new_name
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 检查判定棱镜有没有开
    local function CheckLeginIsWorking()
        -- if TBAT.FNS:IsLeginWorking() then
        --     return true
        -- end
        -- if TBAT.DEBUGGING then
        --     return true
        -- end
        return false
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return function(inst,seed_prefab)
    ----------------------------------------------------------------------------------
    --- 数据库
        if TheWorld.ismastersim then 
            inst:AddComponent("tbat_data")
        end
    ----------------------------------------------------------------------------------
    --- 没开棱镜就不用安装
        if not CheckLeginIsWorking() then
            return
        end
    ----------------------------------------------------------------------------------
    --- 配置目标物品
        inst.seed_prefab = seed_prefab
    ----------------------------------------------------------------------------------
    --- 
        inst.__cluster_num = net_float(inst.GUID, "__cluster_num", "cluseter_num_updated")
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("cluseter_num_updated",name_change_fn)
        end
    ----------------------------------------------------------------------------------
    --- 接受物品
        acceptable_com_install(inst)
    ----------------------------------------------------------------------------------
    --- ismastersim
        if not TheWorld.ismastersim then
            return
        end
    ----------------------------------------------------------------------------------
    --- 等级系统
        level_sys_install(inst)
    ----------------------------------------------------------------------------------
    --- 失败控制器
        inst:AddComponent("tbat_com_action_fail_reason")
        inst.components.tbat_com_action_fail_reason:Add_Reason("accept_fail",TBAT:GetString2(string_index,"accept_fail"))
        inst.components.tbat_com_action_fail_reason:Add_Reason("accept_fail.max",TBAT:GetString2(string_index,"accept_fail.max"))
    ----------------------------------------------------------------------------------
end
