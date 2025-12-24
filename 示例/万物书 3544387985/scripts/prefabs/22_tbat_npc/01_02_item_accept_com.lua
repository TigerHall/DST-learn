--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    物品交易相关代码

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local cmd_data = require("prefabs/22_tbat_npc/01_03_bird_shop_list")  
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
        ---
            local item_prefab = item.prefab
            inst:ForceFacePoint(doer.Transform:GetWorldPosition())
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
            local talks = TBAT:GetString2(inst.prefab,"item_accept_talk") or {}
            local str = talks[math.random(#talks)] or " "
            local override_str = TBAT:GetString2(item_prefab,"traded_str") --- 物品覆盖话语。
            if override_str then
                str = override_str
            end
            inst:PushEvent("force_talk",str)
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
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return acceptable_com_install