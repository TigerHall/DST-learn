--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    物品交易相关代码

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local cmd_data = require("prefabs/09_tbat_plants/07_06_jellyfish_shop_list")  
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
--- 物品接受升级
    local function acceptable_test_fn(inst,item,doer,right_click)
        if cmd_data.comm_list[item.prefab] then
            return true
        end
        for i,temp_data in ipairs(cmd_data.special_list) do
            if temp_data and temp_data.test(inst,item,doer) then
                return true
            end
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        --- 有一定概率不给东西
            if math.random(1000)/1000 < 0.3 then
                if item.components.stackable then
                    item.components.stackable:Get():Remove()
                else
                    item:Remove()
                end
                -- local tar_com = { ["sanity"] = true,["hunger"]=true,["health"] = true}
                -- local ret_target_coms = {}
                -- for com_name, com in pairs(doer.components) do
                --     if tar_com[com_name] and com.GetPercent and com:GetPercent() < 1 then
                --         table.insert(ret_target_coms,com)
                --     end
                -- end
                -- local ret_com = ret_target_coms[math.random(#ret_target_coms)]
                -- if ret_com then
                --     ret_com:SetPercent(1)
                -- end
                inst:PushEvent("dance")
                return false,"item_fail"
            end
        --------------------------------------------------
        ---
            local item_num = 1
            if item.components.stackable then
                item_num = item.components.stackable:StackSize()
            end            
        --------------------------------------------------
        --- 普通物品
            local comm_data = cmd_data.comm_list[item.prefab]
            if comm_data then
                local ret_prefab = comm_data.prefab
                local num = comm_data.num or 1
                TBAT.FNS:GiveItemByPrefab(doer,ret_prefab, num*item_num)
            end
        --------------------------------------------------
        ---
            local remove_blocker_callback = {}
            for i,temp_data in ipairs(cmd_data.special_list) do
                if temp_data and temp_data.test(inst,item,doer) and temp_data.fn then
                    temp_data.fn(inst,item,doer,item_num,remove_blocker_callback)
                end
            end
        --------------------------------------------------
        ---
            if not remove_blocker_callback.blocker_remove then
                item:Remove()
            end
        --------------------------------------------------
        ---
            inst:PushEvent("dance")
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText("tbat_plant_jellyfish",STRINGS.ACTIONS.ADDCOMPOSTABLE)
        replica_com:SetSGAction("give")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)

        --- 交互失败
        inst:AddComponent("tbat_com_action_fail_reason")
        inst.components.tbat_com_action_fail_reason:Add_Reason("item_fail",TBAT:GetString2("tbat_plant_jellyfish","item_fail"))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return function(inst)
    acceptable_com_install(inst)
    if not TheWorld.ismastersim then
        return
    end
end