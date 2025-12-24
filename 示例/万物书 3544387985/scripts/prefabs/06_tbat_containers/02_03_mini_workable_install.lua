--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    容器界面 hook
    
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_container_cherry_blossom_rabbit_mini"
    local normally_can_be_open = true
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 右键使用
    local function workable_test_fn(inst,doer,right_click)
        if inst.replica.inventoryitem:IsGrandOwner(doer) then
            -- inst.replica.tbat_com_workable:SetText(this_prefab,STRINGS.ACTIONS.PLANT.PLANTER)
            if inst.replica.container:IsOpenedBy(doer) then
                inst.replica.tbat_com_workable:SetText(this_prefab,STRINGS.ACTIONS.ACTIVATE.CLOSE)
            else
                inst.replica.tbat_com_workable:SetText(this_prefab,STRINGS.ACTIONS.ACTIVATE.OPEN)
            end
            return true
        end
        if right_click then
            inst.replica.tbat_com_workable:SetText(this_prefab,STRINGS.ACTIONS.PICKUP.GENERIC)
            return true
        end
        return false
    end
    local function workable_on_work_fn(inst,doer)
        if not inst.replica.inventoryitem:IsGrandOwner(doer) then
            inst.components.inventoryitem.canbepickedup = true
            doer.components.inventory:GiveItem(inst)
        else
            local owner = inst.components.inventoryitem.owner
            local com = owner and owner.components.container or owner.components.inventory
            if com then
                -- com:DropItem(inst)
                -- inst.components.container.canbeopened = true
                -- inst.components.container:Open(doer)
                if inst.components.container:IsOpen() then
                    inst.components.container:Close()
                    inst.components.container.canbeopened = normally_can_be_open
                else
                    inst.components.container.canbeopened = true
                    inst.components.container:Open(doer)
                end
            end
        end
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.PICKUP.GENERIC)
        replica_com:SetSGAction("doshortaction")
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function onland_event(inst)
        inst.components.inventoryitem.canbepickedup = false
        inst.components.container.canbeopened = true

    end
    local function on_pickup(inst)
        inst.components.container:Close()
        inst.components.container.canbeopened = normally_can_be_open
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
return function(inst)
    workable_install(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("on_landed",onland_event)
    inst:ListenForEvent("onputininventory",on_pickup)
end