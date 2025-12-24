--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数
    local this_prefab = "tbat_container_cherry_blossom_rabbit_mini"
    local upgrade_item_prefab = "tbat_material_dandycat"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local function acceptable_test_fn(inst,item,doer,right_click)
        if inst.replica.inventoryitem and inst.replica.inventoryitem:IsGrandOwner(doer) then
            return false
        end
        if right_click 
            and (TheWorld.state.isfullmoon or TBAT.DEBUGGING) 
            and item.prefab == upgrade_item_prefab            
            then
            return true
        end
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 
            if inst.components.inventoryitem == nil or inst.components.inventoryitem.owner then
                return false
            end
        --------------------------------------------------
        -- 
            if item.components.stackable then
                item.components.stackable:Get():Remove()
            else
                item:Remove()
            end
        --------------------------------------------------
        --- 
            inst:PushEvent("levelup")
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.UPGRADE.GENERIC)
        replica_com:SetSGAction("dolongaction")
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
--- 升级
    local function level_up_event(inst)
        -----------------------------------------------------------------
        --- 前置准备
            inst.components.container:Close()
            inst:AddTag("INLIMBO")
            inst:AddTag("NOCLICK")
            inst:AddTag("CLASSIFIED")
            inst.components.container.canbeopened = false
            inst.components.inventoryitem.canbepickedup = false
            inst:RemoveComponent("inventoryitem")
        -----------------------------------------------------------------
        ---
            inst.AnimState:PlayAnimation("grow_1",false)
        -----------------------------------------------------------------
        ---
            inst:ListenForEvent("animover",function()
                
                local dropped_items = {}
                local item_records = {}
                for index = 1, inst.components.container:GetNumSlots(), 1 do
                    local item = inst.components.container:GetItemInSlot(index)
                    if item then
                        if item:HasOneOfTags({ "nonpotatable", "irreplaceable" }) then
                            table.insert(dropped_items, item)
                            inst.components.container:DropItemBySlot(index)
                        else
                            item_records[item.prefab] = item_records[item.prefab] or {}
                            local record = item:GetSaveRecord()
                            item:Remove()
                            table.insert(item_records[item.prefab], record)
                        end
                    end
                end

                local x,y,z = inst.Transform:GetWorldPosition()
                local current_skin_data = inst.components.tbat_com_skin_data:GetCurrentData()
                inst:Remove()
                local new_box = SpawnPrefab("tbat_container_cherry_blossom_rabbit")
                ---------------------------------------------------
                ---
                    if current_skin_data and current_skin_data.skin_link then
                        new_box.components.tbat_com_skin_data:SetCurrent(current_skin_data.skin_link)
                    end
                ---------------------------------------------------
                new_box.Transform:SetPosition(x,y,z)
                for k, item in pairs(dropped_items) do
                    new_box.components.container:GiveItem(item)
                end
                for prefab, data in pairs(item_records) do
                    for k, record in pairs(data) do
                        local item = SpawnSaveRecord(record)
                        new_box.components.container:GiveItem(item)
                    end
                end

            end)
        -----------------------------------------------------------------
        -----------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    acceptable_com_install(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("levelup", level_up_event)
end