--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 扫描寻找 不在 玩家身上的 物品。
    local function start_search_items(inst,data)
        -- if inst.components.container:IsFull() then            
        --     return
        -- end
        -------------------------------------------------------------------------------
        -- 扫描当前可叠堆的物品
            local current_stackable_item_prefab = {}
            inst.components.container:ForEachItem(function(item)
                if item and item.components.stackable then
                    current_stackable_item_prefab[item.prefab] = true
                end
            end)
        -------------------------------------------------------------------------------
        ---
            local function can_put_into_container(item)
                local owner = item.components.inventoryitem:GetGrandOwner()
                if owner and ( owner == inst or owner.prefab == inst.prefab ) then
                    return false
                end
                if current_stackable_item_prefab[item.prefab] then
                    return true
                end
                if not inst.components.container:IsFull() then
                    return true
                end
                return false
            end
        -------------------------------------------------------------------------------
        --- 
            local got_item_flag = false
        -------------------------------------------------------------------------------
        --- 开始遍历寻找
            local all_papers = TBAT.FNS:GetAllErasablePapers(inst.Transform:GetWorldPosition())
            for k, target_inst in pairs(all_papers) do
                if can_put_into_container(target_inst) then
                    local save_record = target_inst:GetSaveRecord()
                    target_inst:Remove()
                    inst.components.container:GiveItem(SpawnSaveRecord(save_record))
                    got_item_flag = true
                end
            end
        -------------------------------------------------------------------------------
        ---
            if got_item_flag then
                local str_table = TBAT:GetString2(inst.prefab,"search_announce") or {}
                local str = str_table[math.random(#str_table)]
                if str then
                    inst:WhisperTo(nil,str) -- 广播通知
                end
            end
        -------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- erasa button 擦除动作
    local function do_erasa(inst,data)
        local userid = data.userid
        local doer = LookupPlayerInstByUserID(userid)
        if doer == nil then
            return
        end
        local do_erasa_flag = false
        inst.components.container:ForEachItem(function(item)
            if item and item.components.erasablepaper then
                if item.components.stackable then
                    local stack_num = item.components.stackable:StackSize()
                    local ret_prefab = item.components.erasablepaper.erased_prefab
                    TBAT.FNS:GiveItemByPrefab(doer, ret_prefab, stack_num)
                    item:Remove()
                else
                    item.components.erasablepaper:DoErase(inst,doer) 
                end
                do_erasa_flag = true
            end
        end)
        if do_erasa_flag then
            local str_table = TBAT:GetString2(inst.prefab,"erasa_announce") or {}
            local str = str_table[math.random(#str_table)]
            if str then
                inst:WhisperTo(doer,str)
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    return function(inst)
        -------------------------------------------------------------------------------
        --- 按钮事件  search_button_clicked  erasa_button_clicked
            inst:ListenForEvent("search_button_clicked",start_search_items)
            inst:ListenForEvent("erasa_button_clicked",do_erasa)
        -------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------